package org.cloud.sonic.agent.tests.ios;

import com.alibaba.fastjson.JSONObject;
import org.cloud.sonic.agent.automation.IOSStepHandler;
import org.cloud.sonic.agent.bridge.ios.SibTool;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * 暂未开放
 */
public class IOSPerfDataThread extends Thread {

    private final Logger log = LoggerFactory.getLogger(IOSPerfDataThread.class);

    public final static String IOS_PERF_DATA_TASK_PRE = "ios-perf-data-task-%s-%s-%s";

    private final IOSTestTaskBootThread iosTestTaskBootThread;

    public IOSPerfDataThread(IOSTestTaskBootThread iosTestTaskBootThread) {
        this.iosTestTaskBootThread = iosTestTaskBootThread;

        this.setDaemon(true);
        this.setName(iosTestTaskBootThread.formatThreadName(IOS_PERF_DATA_TASK_PRE));
    }

    public IOSTestTaskBootThread getIosTestTaskBootThread() {
        return iosTestTaskBootThread;
    }

    @Override
    public void run() {
        JSONObject perf = iosTestTaskBootThread.getJsonObject().getJSONObject("perf");
        if (perf.getInteger("isOpen") == 1) {
            String udId = iosTestTaskBootThread.getUdId();
            IOSStepHandler iosStepHandler = iosTestTaskBootThread.getIosStepHandler();
            SibTool.startPerfmon(udId, "", null,
                    iosStepHandler.getLog(), perf.getInteger("perfInterval"));
            boolean hasTarget = false;
            while (iosTestTaskBootThread.getRunStepThread().isAlive()) {
                try {
                    Thread.sleep(500);
                } catch (InterruptedException e) {
                    break;
                }
                if (iosStepHandler.getTargetPackage().length() != 0 && !hasTarget) {
                    SibTool.startPerfmon(udId, iosStepHandler.getTargetPackage(), null,
                            iosStepHandler.getLog(), perf.getInteger("perfInterval"));
                    hasTarget = true;
                }
            }
            SibTool.stopPerfmon(udId);
        }
    }
}
