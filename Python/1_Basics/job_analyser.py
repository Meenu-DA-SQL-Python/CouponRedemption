def salary(salary_1,salary_2=0.1):
    salary=salary_1*(1+salary_2)
    return salary
"""
Total_salary with bonus has to be used to calulate the bonus rate.
base salary value is provided
"""
def cal_bonus(total_salary,base_salary):
    """
    Total_salary with bonus has to be used to calulate the bonus rate.
    base salary value is provided
    """ 
    return (total_salary-base_salary)/base_salary

def annual_salary(hourly_rate,weeks_hour):
    """
    Annual salary is calculated by the product of hourly_rate,weeks_hourand 52
    """
    return hourly_rate * weeks_hour * 52
    
def filter_by_location(job_postings, location):
    return [job for job in job_postings if job['location'] == location]
    

    
