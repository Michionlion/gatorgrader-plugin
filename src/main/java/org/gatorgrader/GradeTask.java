package org.gatorgrader;

import org.gradle.api.DefaultTask;
import org.gradle.api.tasks.TaskAction;

public class GradeTask extends DefaultTask {
    @TaskAction
    public void executeTask() {
        System.out.println("Hello, Work! Doing grading...");
    }
}
