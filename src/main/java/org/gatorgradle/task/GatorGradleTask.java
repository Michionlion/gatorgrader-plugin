package org.gatorgradle.task;

import java.io.File;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.ObjectStreamException;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

import javax.inject.Inject;

import org.gatorgradle.GatorGradlePlugin;
import org.gatorgradle.command.BasicCommand;
import org.gatorgradle.command.Command;
import org.gatorgradle.command.GatorGraderCommand;
import org.gatorgradle.config.GatorGradleConfig;
import org.gatorgradle.display.CommandOutputSummary;
import org.gatorgradle.internal.DependencyManager;
import org.gatorgradle.internal.ProgressLoggerWrapper;
import org.gatorgradle.util.Console;

import org.gradle.api.DefaultTask;
import org.gradle.api.GradleException;
import org.gradle.api.logging.Logger;
import org.gradle.api.tasks.Input;
import org.gradle.api.tasks.InputDirectory;
import org.gradle.api.tasks.TaskAction;
import org.gradle.workers.IsolationMode;
import org.gradle.workers.WorkerExecutor;

public class GatorGradleTask extends DefaultTask {

  protected GatorGradleConfig config;
  protected File workingDir;

  protected static CommandOutputSummary summary;

  public void setConfig(GatorGradleConfig config) {
    this.config = config;
  }

  /**
   * Dependency management.
   */
  protected void act() {
    config.parseHeader();

    // ensure GatorGrader and dependencies are installed
    String dep = DependencyManager.manage();
    if (!dep.isEmpty()) {
      throw new GradleException(dep);
    }

    Console.newline(1);

    if (config.hasStartupCommand()) {
      Console.log("Starting up...");
      BasicCommand startup = (BasicCommand) config.getStartupCommand();
      startup.outputToSysOut(true);
      startup.run();
      if (startup.exitValue() != Command.SUCCESS) {
        throw new GradleException(
            "Startup command '" + startup + "' failed with exit code "
            + startup.exitValue() + "!"
        );
      }
      Console.log("Ready!");
    }

    Console.newline(2);

    config.parseBody();
  }

  @Input
  public GatorGradleConfig getConfig() {
    return config;
  }

  public void setWorkingDir(File dir) {
    this.workingDir = dir;
  }

  @InputDirectory
  public File getWorkingDir() {
    return workingDir;
  }
}
