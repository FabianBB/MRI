# -*- coding: utf-8 -*-
"""
Created on Fri Dec 15 10:03:47 2023

@author: valen
"""
import numpy as np
import math

# Class for the schedules
class RMI:
    def __init__(self):
        self.patient1 = []
        self.patient2 = []
        # schedules for rmi facility 1 and 2
        self.schedule1 = []
        self.schedule2 = []
        self.waiting_times = []
        self.idle_times = []
        self.overtime_times = []
        self.ending_times_of_each_day = []

    # Calculate the starting time, end time of the appointment 
    # and all the relevant information for the patients
    def schedule_patient(self, day_list1, day_list2, appointment_time_list1, appointment_time_list2, duration_mean, duration_variance, duration_alpha, duration_beta, fixed_duration1, fixed_duration2):
    
        while len(appointment_time_list1) > 0 or len(appointment_time_list2) > 0:
            # Check which patient type called first and consider the correct parameters
            if len(appointment_time_list1) > 0 and len(appointment_time_list2) > 0:
                if (appointment_time_list1[0] < appointment_time_list2[0]):
                    appointment_time = appointment_time_list1.pop(0)
                    day = day_list1.pop(0)
                    fixed_duration = fixed_duration1
                    random = np.random.normal(duration_mean, duration_variance)

                else:
                    appointment_time = appointment_time_list2.pop(0)
                    day = day_list2.pop(0)
                    fixed_duration = fixed_duration2
                    random = np.random.gamma(duration_alpha, duration_beta)
            # If only type 1 are left, we do not have to consider type 2 to select the relevant parameters
            elif len(appointment_time_list1) > 0 and len(appointment_time_list2) <= 0:
                appointment_time = appointment_time_list1.pop(0)
                day = day_list1.pop(0)
                fixed_duration = fixed_duration1
                random = np.random.normal(duration_mean, duration_variance)
            # If only type 2 are left, we do not have to consider type 1 to select the relevant parameters
            elif len(appointment_time_list1) <= 0 and len(appointment_time_list2) > 0:
                appointment_time = appointment_time_list2.pop(0)
                day = day_list2.pop(0)
                fixed_duration = fixed_duration2
                random = np.random.gamma(duration_alpha, duration_beta)
             
            # Check if we schedule the patient in the first or second RMI facility based on which one is available first
            # Facility 1 available first
            if (self.schedule1[-1][0] if self.schedule1 else 0) <= (self.schedule2[-1][0] if self.schedule2 else 0):
                time = max(appointment_time, self.schedule1[-1][0] if self.schedule1 else appointment_time)
                # Calculate all the relevant information
                if time > day * 9 and (self.schedule1[-1][1] + fixed_duration) <= (math.floor(self.schedule1[-1][1]/9)+1)*9 :
                     start_time = time
                     theoretical_end_time = self.schedule1[-1][1] + fixed_duration
                else :      
                        start_time = max((day) * 9, math.floor((self.schedule1[-1][1] + fixed_duration)/9)*9 if self.schedule1 else 0)
                        theoretical_end_time = start_time + fixed_duration
                        
                end_time = start_time + random
                waiting_time = start_time - appointment_time
                idle_time = max(0, start_time - (self.schedule1[-1][0] if self.schedule1 else 9))            
                scheduling_day = math.floor(start_time/9)
                overtime = max(0, end_time -  9 * (scheduling_day+1))
                
                if overtime > 0:
                    end_time = end_time - overtime
                    
                self.waiting_times.append(waiting_time)
                self.idle_times.append(idle_time)
                self.overtime_times.append(overtime)
                    
                self.schedule1.append((end_time, theoretical_end_time))

            # Facility 2 available first         
            else:
                time = max(appointment_time, self.schedule2[-1][0] if self.schedule2 else appointment_time)
                if time > day * 9 and (self.schedule2[-1][1] + fixed_duration) <= (math.floor(self.schedule2[-1][1]/9)+1)*9 :
                    start_time = time
                    theoretical_end_time = self.schedule2[-1][1] + fixed_duration
                else :      
                    start_time = max((day) * 9, math.floor((self.schedule2[-1][1]+ fixed_duration)/9)*9 if self.schedule2 else 0)
                    theoretical_end_time = start_time + fixed_duration
            
                end_time = start_time + random
                waiting_time = start_time - appointment_time
                idle_time = max(0, start_time - (self.schedule2[-1][0] if self.schedule2 else 9))            
                scheduling_day = math.floor(start_time/9)
                overtime = max(0, end_time -  9 * (scheduling_day+1))
            
                if overtime > 0:
                    end_time = end_time - overtime
                
                self.waiting_times.append(waiting_time)
                self.idle_times.append(idle_time)
                self.overtime_times.append(overtime)
        
                self.schedule2.append((end_time, theoretical_end_time)) 
            
# simulation that generates patients for the desired amount of time according to arrival rate
def run_simulation(interarrival_mean1, interarrival_mean2, interarrival_var, duration_mean, duration_variance, duration_alpha, duration_beta, fixed_duration1, fixed_duration2, days):
    rmi = RMI()
    cumulative_time1 = 0
    cumulative_time2 = 0
    patient_1 = []
    patient_2 = []
    day_list1 = []
    day_list2 = []

    while cumulative_time1 + cumulative_time2 < 2 * 9 * days:  # Continue generating patients without resetting interarrival times
        if cumulative_time1 < 9 * days: # Makes sure the calls for patient 1 does not exceed the day limit
            interarrival_time1 = np.random.exponential(interarrival_mean1)
            cumulative_time1 += interarrival_time1
            if cumulative_time1 < 9 * days: # Makes sure we don't add the last patient who is calling after the day limit
                day = math.floor(cumulative_time1/9) + 1
                day_list1.append(day)
                patient_1.append(cumulative_time1)
            
        if cumulative_time2 < 9 * days: # Makes sure the calls for patient 2 does not exceed the day limit
            interarrival_time2 = np.random.normal(interarrival_mean2, interarrival_var)
            cumulative_time2 += interarrival_time2
            if cumulative_time2 < 9 * days: # Makes sure won't add the last patient who is calling after the day limit
                day = math.floor(cumulative_time2/9) + 1
                day_list2.append(day)
                patient_2.append(cumulative_time2)
            

    rmi.schedule_patient(day_list1, day_list2, patient_1, patient_2, duration_mean, duration_variance, duration_alpha, duration_beta, fixed_duration1, fixed_duration2)

    return rmi

# Simulation parameters
interarrival_mean1 = 0.515947  # Mean of exponential interarrival time
duration_mean = 0.432754  # Mean of normal distribution for appointment duration
duration_variance = 0.097585  # Variance of normal distribution for appointment duration
fixed_duration1 = 0.432754
# Simulation parameters
interarrival_mean2 = 0.8674233  # Mean of normally distributed interarrival time
interarrival_var = 0.3102543
duration_alpha = 12.67705  # alpha of gamma distribution for appointment duration
duration_beta = 0.052831  # beta of gamma distribution for appointment duration
fixed_duration2 = 12.67705*0.052831

# Define the number of times to run the simulation
num_simulations = 10000  # You can adjust this value as needed

# Initialize lists to store results from each simulation
all_waiting_times = []
all_idle_times = []
all_overtime_times = []
total_patients = []

for _ in range(num_simulations):
    # Run the simulation
    office = run_simulation(interarrival_mean1, interarrival_mean2, interarrival_var, duration_mean, duration_variance, duration_alpha, duration_beta, fixed_duration1, fixed_duration2, days=31)
    
    # Collect results for each simulation run
    all_waiting_times.append(np.mean(office.waiting_times))
    all_idle_times.append(np.mean(office.idle_times))
    all_overtime_times.append(np.mean(office.overtime_times))
    total_patients.append(len(office.schedule1) + len(office.schedule2))  # Store total patients treated in this simulation run

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