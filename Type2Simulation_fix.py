# -*- coding: utf-8 -*-
"""
Created on Fri Dec  8 15:30:36 2023

@author: Valentin Michaux
"""

import numpy as np
import math

# Class for the schedule
class RMI:
    def __init__(self):
        # schedule rmi facility
        self.schedule = []
        self.waiting_times = []
        self.idle_times = []
        self.overtime_times = []

    # Calculate the starting time, end time of the appointment 
    # and all the relevant information for the patient
    def schedule_patient(self, patient, calling_time, duration_alpha, duration_beta, fixed_duration, day):
        
        # Determine if the patient can be allocated on the same day as the previous one or
        # if he has to be allocated to the beginning of the next day
        time = max(calling_time, self.schedule[-1][0] if self.schedule else calling_time)
        if time > day * 9 and (self.schedule[-1][2] + fixed_duration) <= (math.floor(self.schedule[-1][2]/9)+1)*9 :
            start_time = time
            theoretical_end_time = self.schedule[-1][2] + fixed_duration
        else :  
            start_time = max((day) * 9, math.floor((self.schedule[-1][2]+ fixed_duration)/9)*9 if self.schedule else 0)
            theoretical_end_time = start_time + fixed_duration

        # Real duration of the appointment
        end_time = start_time + np.random.gamma(duration_alpha, duration_beta)
        waiting_time = start_time - calling_time
        idle_time = max(0, start_time - (self.schedule[-1][0] if self.schedule else 9)) 
        scheduling_day = math.floor(start_time/9)
        overtime = max(0, end_time -  9 * (scheduling_day+1))
        
        if overtime > 0:
            end_time = end_time - overtime
            
        self.waiting_times.append(waiting_time)
        self.idle_times.append(idle_time)
        self.overtime_times.append(overtime)

        self.schedule.append((end_time, patient, theoretical_end_time))
    
        return True

# simulation that generates patients for the desired amount of time according to arrival rate
def run_simulation(interarrival_mean, interarrival_var, duration_alpha, duration_beta, fixed_duration, days):
    rmi = RMI()
    total_patients_treated = 0
    cumulative_time = 0

    while cumulative_time < 9 * days:  # Continue generating patients without resetting interarrival times
        interarrival_time = np.random.exponential(interarrival_mean)
        cumulative_time += interarrival_time
        
        if cumulative_time < 9 * days:
            patient = f"Patient_{cumulative_time}"
            day = math.floor(cumulative_time/9) + 1
        # add patient to the system
            appointment_scheduled = rmi.schedule_patient(
            patient, cumulative_time, duration_alpha, duration_beta, fixed_duration, day
            )
        if appointment_scheduled:
            total_patients_treated += 1
                

    return rmi

# Simulation parameters
interarrival_mean = 0.8674233  # Mean of normally distributed interarrival time
interarrival_var = 0.3102543 # Sd of normally distributed interarrival time
duration_alpha = 12.67705  # alpha of gamma distribution for appointment duration
duration_beta = 0.052831  # beta of gamma distribution for appointment duration
fixed_duration = 1.0 # fixed duration that will determine our schedule



# Define the number of times to run the simulation
num_simulations = 10000  # You can adjust this value as needed
days = 31
# Initialize lists to store results from each simulation
all_waiting_times = []
all_idle_times = []
all_overtime_times = []
total_patients = []

for _ in range(num_simulations):
    # Run the simulation num_simulation times
    rmi_simulation = run_simulation(interarrival_mean, interarrival_var, duration_alpha, duration_beta, fixed_duration, days)
    
    # Collect results for each simulation run
    all_waiting_times.append(np.mean(rmi_simulation.waiting_times))
    all_idle_times.append(np.mean(rmi_simulation.idle_times))
    all_overtime_times.append(np.mean(rmi_simulation.overtime_times))
    total_patients.append(len(rmi_simulation.schedule))  # Store total patients treated in this simulation run

# Calculate the sum of total patients across all simulations
sum_total_patients = np.sum(total_patients)
avg_sum_total_patients = math.floor(sum_total_patients/num_simulations)

# Calculate the average of each parameter over all simulations
average_waiting_time = np.mean(all_waiting_times)
average_idle_time = np.mean(all_idle_times)
average_overtime = np.mean(all_overtime_times)

# Calculate the maximum of each parameter over all simulations
max_waiting_time = np.max(all_waiting_times)
max_idle_time = np.max(all_idle_times)
max_overtime = np.max(all_overtime_times)

# Print the results
print("Total Patients Treated:", sum_total_patients)
print("Average Patients Treated:",  avg_sum_total_patients)
print("\nAverage Waiting Time:", average_waiting_time)
print("Max Waiting Time:", max_waiting_time)

print("\nAverage Idle Time:", average_idle_time)
print("Max Idle Time:", max_idle_time)

print("\nAverage Overtime:", average_overtime)
print("Max Overtime:", max_overtime)
