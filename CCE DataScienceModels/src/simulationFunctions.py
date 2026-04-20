import matplotlib.pyplot as plt
import matplotlib.animation as animation
import numpy as np
import datetime
import src.featureEngineeringHelpers as featEng
import pandas as pd

fig, ax = plt.subplots(1, 1)
ax.plot([], [], 'b', [], [], 'r')
plt.legend(['yPredicted', 'yActual'])
lines = ax.lines

def simulate(simFunc, testDF, predictorTags, responseTags, refTags):
    # timestamp, xTest, yTest, refTest
    # Define plotting function
    predictors = testDF[predictorTags].values
    responses = testDF[responseTags].values
    refs = testDF[refTags].values

    def animate(step):
        currentxdata = ax.lines[0].get_xdata()
        newxdata = np.append(currentxdata, step)
        currenty1data = ax.lines[0].get_ydata()
        currenty2data = ax.lines[1].get_ydata()
        newy1data = np.append(currenty1data, simFunc(predictors[step]))
        newy2data = np.append(currenty2data, refs[step])


        xmin, xmax = ax.get_xlim()
        ax.set_xlim(step-100, step+20)

        ymin, ymax = ax.get_ylim()
        if responses[step] >= ymax:
            ax.set_ylim(ymin, responses[step]*1.4)
        if responses[step] <= ymin:
            ax.set_ylim(responses[step], ymax)
        ax.figure.canvas.draw()


        lines[0].set_data(newxdata, newy1data)
        lines[1].set_data(newxdata, newy2data)
        return lines

    # For-loop that simulates over data points and updates plot
    # Update plot
    num_steps = len(testDF)
    anim = animation.FuncAnimation(fig, animate, num_steps, interval=100, repeat=True)
    plt.show()
    #
    # writergif = animation.PillowWriter(fps=30)
    # anim.save('test.gif', writer=writergif)

def performStepTest(simFunc, sim_run):
    sim_run['baselineResponse'] = simFunc(sim_run['baselinePredictors'])
    sim_run['stepResponse'] = simFunc(sim_run['stepPredictors'])

    return sim_run

def prepareStepTest(fullDFOrig, stepSize, predictorTags, mvTag, processingFunc):
    sim_run = {'df': [], 'baselinePredictors': [], 'stepPredictors': [], 'baselineResponse': [], 'stepResponse': [],
               'stepSize': []}
    step_data_orig = fullDFOrig.copy()

    sim_run['df'] = step_data_orig
    sim_run['stepSize'] = stepSize

    sim_run['baselinePredictors'] = processingFunc(sim_run['df'])[0][predictorTags]

    step_start = step_data_orig.index[int(len(step_data_orig) / 2)]  # Perform the step 50% into the data
    step_index = step_data_orig.index > step_start
    step_data_orig[mvTag][step_index] = (step_data_orig[mvTag][step_index] * (1 + stepSize))

    # Use step data to get predictions
    sim_run['stepPredictors'] = processingFunc(step_data_orig)[0][predictorTags]

    return sim_run

def createStepTestPlots(sim_run, responseTag, mvTag, heading, disturbanceTags=[]):
    originalResponse = sim_run['df'][responseTag]
    baselineResponse = sim_run['baselineResponse']
    stepResponse = sim_run['stepResponse']
    baselineMV = sim_run['baselinePredictors'][mvTag]
    stepMV = sim_run['stepPredictors'][mvTag]
    stepSize = sim_run['stepSize']*100

    if disturbanceTags:
        disturbanceDf = sim_run['df'][disturbanceTags]
    else:
        disturbanceDf = pd.DataFrame()

    idx = baselineMV.index
    subplotNum = 2 + len(disturbanceDf.columns)
    fig, axs = plt.subplots(subplotNum, sharex=True)

    # if sim_run['constantPredictors'] == False:
    #     axs[0].plot(originalResponse.index, originalResponse, color = 'c')
    #     label = ['Actual ' + originalResponse.name, 'Baseline', f'Step: {stepSize}' + '%']
    # else:
    label = ['Baseline', f'Step: {stepSize}' + '%']

    axs[0].plot(idx, baselineResponse, color = 'b')
    axs[0].plot(idx, stepResponse, color = 'g')
    axs[0].legend(label)
    axs[0].set_ylabel('Predicted ' + responseTag[0])

    axs[1].title.set_text(heading)
    axs[1].plot(idx, baselineMV.values, color = 'b')
    axs[1].plot(idx, stepMV, color = 'g')
    axs[1].legend(['Baseline', f'Step: {stepSize}' + '%'])
    axs[1].set_ylabel(baselineMV.name)

    if disturbanceDf.empty == False:
        for i in range(2,subplotNum):
            colName = disturbanceDf.columns[i-2]
            axs[i].plot(sim_run['df'].index, disturbanceDf[colName])
            axs[i].set_ylabel(colName)

    plt.show()