/*
 *  Copyright (C) [SonicCloudOrg] Sonic Project
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *         http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 */
package org.cloud.sonic.agent.websockets;

import lombok.extern.slf4j.Slf4j;
import org.cloud.sonic.agent.bridge.ios.SibTool;
import org.cloud.sonic.agent.common.config.WsEndpointConfigure;
import org.cloud.sonic.agent.common.maps.WebSocketSessionMap;
import org.cloud.sonic.agent.tests.ios.mjpeg.MjpegInputStream;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.websocket.OnClose;
import javax.websocket.OnError;
import javax.websocket.OnOpen;
import javax.websocket.Session;
import javax.websocket.server.PathParam;
import javax.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.ByteBuffer;

import static org.cloud.sonic.agent.tools.BytesTool.sendByte;

@Component
@Slf4j
@ServerEndpoint(value = "/websockets/ios/screen/{key}/{udId}/{token}", configurator = WsEndpointConfigure.class)
public class IOSScreenWSServer implements IIOSWSServer {
    @Value("${sonic.agent.key}")
    private String key;
    @Value("${sonic.agent.port}")
    private int port;

    @OnOpen
    public void onOpen(Session session, @PathParam("key") String secretKey,
                       @PathParam("udId") String udId, @PathParam("token") String token) throws InterruptedException {
        if (secretKey.length() == 0 || (!secretKey.equals(key)) || token.length() == 0) {
            log.info("拦截访问！");
            return;
        }

        WebSocketSessionMap.addSession(session);
        if (!SibTool.getDeviceList().contains(udId)) {
            log.info("设备未连接，请检查！");
            return;
        }
        saveUdIdMapAndSet(session, udId);

        int screenPort = 0;
        int wait = 0;
        while (wait < 120) {
            Integer p = IOSWSServer.screenMap.get(udId);
            if (p != null) {
                screenPort = p;
                break;
            }
            Thread.sleep(500);
            wait++;
        }
        if (screenPort == 0) {
            return;
        }
        int finalScreenPort = screenPort;
        new Thread(() -> {
            URL url;
            try {
                url = new URL("http://localhost:" + finalScreenPort);
            } catch (MalformedURLException e) {
                return;
            }
            MjpegInputStream mjpegInputStream = null;
            try {
                mjpegInputStream = new MjpegInputStream(url.openStream());
            } catch (IOException e) {
                log.info(e.getMessage());
            }
            ByteBuffer bufferedImage;
            int i = 0;
            while (true) {
                try {
                    if ((bufferedImage = mjpegInputStream.readFrameForByteBuffer()) == null) break;
                } catch (IOException e) {
                    log.info(e.getMessage());
                    break;
                }
                i++;
                if (i % 3 != 0) {
                    sendByte(session, bufferedImage);
                } else {
                    i = 0;
                }
            }
            try {
                mjpegInputStream.close();
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            log.info("screen done.");
        }).start();
    }

    @OnClose
    public void onClose(Session session) {
        exit(session);
    }

    @OnError
    public void onError(Session session, Throwable error) {
        log.error(error.getMessage());
    }

    private void exit(Session session) {
        String udId = udIdMap.get(session);
        WebSocketSessionMap.removeSession(session);
        removeUdIdMapAndSet(session);
        try {
            session.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        log.info("{} : quit.", session.getId());
    }
}