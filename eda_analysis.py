"""
Banking Delinquency Prediction - Exploratory Data Analysis
===========================================================
Author: Mohit Kumar
Purpose: Comprehensive EDA and visualization for banking delinquency data
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sqlalchemy import create_engine
import warnings
warnings.filterwarnings('ignore')

# Set visualization style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)
plt.rcParams['font.size'] = 10

class BankingDelinquencyEDA:
    """
    Comprehensive EDA class for banking delinquency analysis
    """
    
    def __init__(self, connection_string):
        """
        Initialize EDA with database connection
        
        Parameters:
        -----------
        connection_string : str
            Database connection string (e.g., 'postgresql://user:pass@localhost/dbname')
        """
        self.engine = create_engine(connection_string)
        self.df = None
        
    def load_data(self):
        """Load data from database"""
        query = "SELECT * FROM delinquency_prediction"
        self.df = pd.read_sql(query, self.engine)
        print(f"Data loaded: {self.df.shape[0]} rows, {self.df.shape[1]} columns")
        return self.df
    
    def data_overview(self):
        """Display basic data information"""
        print("\n" + "="*60)
        print("DATA OVERVIEW")
        print("="*60)
        
        print("\nDataset Shape:", self.df.shape)
        print("\nColumn Data Types:")
        print(self.df.dtypes)
        
        print("\nMissing Values:")
        missing = self.df.isnull().sum()
        missing_pct = (missing / len(self.df)) * 100
        missing_df = pd.DataFrame({
            'Missing Count': missing,
            'Percentage': missing_pct
        })
        print(missing_df[missing_df['Missing Count'] > 0])
        
        print("\nBasic Statistics:")
        print(self.df.describe())
    
    def calculate_risk_score(self):
        """Calculate delinquency risk scores"""
        self.df['risk_score'] = (
            (self.df['missed_payments'] / 6.0) * 0.30 +
            self.df['credit_utilization'] * 0.25 +
            ((850 - self.df['credit_score']) / 850.0) * 0.25 +
            self.df['debt_to_income_ratio'] * 0.20
        )
        
        # Risk tier classification
        self.df['risk_tier'] = pd.cut(
            self.df['risk_score'],
            bins=[0, 0.30, 0.70, 1.0],
            labels=['LOW', 'MEDIUM', 'HIGH']
        )
        
        print("\nRisk Score calculated and added to dataframe")
        return self.df
    
    def plot_risk_distribution(self, save_path=None):
        """Plot risk tier distribution"""
        fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
        
        # Risk tier counts
        risk_counts = self.df['risk_tier'].value_counts()
        ax1.bar(risk_counts.index, risk_counts.values, 
                color=['green', 'orange', 'red'])
        ax1.set_title('Risk Tier Distribution', fontsize=14, fontweight='bold')
        ax1.set_xlabel('Risk Tier')
        ax1.set_ylabel('Number of Customers')
        ax1.grid(axis='y', alpha=0.3)
        
        # Add value labels
        for i, v in enumerate(risk_counts.values):
            ax1.text(i, v + 5, str(v), ha='center', fontweight='bold')
        
        # Risk score distribution
        ax2.hist(self.df['risk_score'], bins=30, color='steelblue', 
                 edgecolor='black', alpha=0.7)
        ax2.axvline(x=0.30, color='orange', linestyle='--', 
                    label='Low/Medium Threshold')
        ax2.axvline(x=0.70, color='red', linestyle='--', 
                    label='Medium/High Threshold')
        ax2.set_title('Risk Score Distribution', fontsize=14, fontweight='bold')
        ax2.set_xlabel('Risk Score')
        ax2.set_ylabel('Frequency')
        ax2.legend()
        ax2.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_feature_correlation(self, save_path=None):
        """Plot correlation heatmap"""
        numeric_cols = ['age', 'income', 'credit_score', 'credit_utilization',
                       'missed_payments', 'debt_to_income_ratio', 
                       'delinquent_account', 'risk_score']
        
        corr_matrix = self.df[numeric_cols].corr()
        
        plt.figure(figsize=(10, 8))
        sns.heatmap(corr_matrix, annot=True, fmt='.2f', cmap='coolwarm',
                   center=0, square=True, linewidths=1)
        plt.title('Feature Correlation Matrix', fontsize=14, fontweight='bold')
        plt.tight_layout()
        
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_risk_by_demographics(self, save_path=None):
        """Plot risk analysis by demographics"""
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # 1. Income vs Risk
        income_risk = self.df.groupby(
            pd.cut(self.df['income'], bins=5)
        )['risk_score'].mean().sort_values()
        
        axes[0, 0].barh(range(len(income_risk)), income_risk.values, 
                        color='steelblue')
        axes[0, 0].set_yticks(range(len(income_risk)))
        axes[0, 0].set_yticklabels([str(x) for x in income_risk.index])
        axes[0, 0].set_title('Average Risk Score by Income Level', 
                            fontsize=12, fontweight='bold')
        axes[0, 0].set_xlabel('Average Risk Score')
        axes[0, 0].grid(axis='x', alpha=0.3)
        
        # 2. Employment Status vs Risk
        emp_risk = self.df.groupby('employment_status')['risk_score'].mean().sort_values()
        axes[0, 1].barh(range(len(emp_risk)), emp_risk.values, color='coral')
        axes[0, 1].set_yticks(range(len(emp_risk)))
        axes[0, 1].set_yticklabels(emp_risk.index)
        axes[0, 1].set_title('Average Risk Score by Employment Status', 
                            fontsize=12, fontweight='bold')
        axes[0, 1].set_xlabel('Average Risk Score')
        axes[0, 1].grid(axis='x', alpha=0.3)
        
        # 3. Credit Card Type vs Risk
        card_risk = self.df.groupby('credit_card_type')['risk_score'].mean().sort_values()
        axes[1, 0].barh(range(len(card_risk)), card_risk.values, color='lightgreen')
        axes[1, 0].set_yticks(range(len(card_risk)))
        axes[1, 0].set_yticklabels(card_risk.index)
        axes[1, 0].set_title('Average Risk Score by Credit Card Type', 
                            fontsize=12, fontweight='bold')
        axes[1, 0].set_xlabel('Average Risk Score')
        axes[1, 0].grid(axis='x', alpha=0.3)
        
        # 4. Location vs Risk
        location_risk = self.df.groupby('location')['risk_score'].mean().sort_values()
        axes[1, 1].barh(range(len(location_risk)), location_risk.values, 
                       color='plum')
        axes[1, 1].set_yticks(range(len(location_risk)))
        axes[1, 1].set_yticklabels(location_risk.index)
        axes[1, 1].set_title('Average Risk Score by Location', 
                            fontsize=12, fontweight='bold')
        axes[1, 1].set_xlabel('Average Risk Score')
        axes[1, 1].grid(axis='x', alpha=0.3)
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def plot_payment_patterns(self, save_path=None):
        """Analyze 6-month payment patterns"""
        months = ['month_1', 'month_2', 'month_3', 'month_4', 'month_5', 'month_6']
        
        payment_counts = {}
        for month in months:
            payment_counts[month] = self.df[month].value_counts()
        
        # Create stacked bar chart
        payment_df = pd.DataFrame(payment_counts).T
        payment_df = payment_df.fillna(0)
        
        fig, ax = plt.subplots(figsize=(12, 6))
        payment_df.plot(kind='bar', stacked=True, ax=ax, 
                       color=['green', 'orange', 'red'])
        ax.set_title('Payment Pattern Over 6 Months', 
                    fontsize=14, fontweight='bold')
        ax.set_xlabel('Month (1=Most Recent)')
        ax.set_ylabel('Number of Customers')
        ax.set_xticklabels([f'Month {i+1}' for i in range(6)], rotation=0)
        ax.legend(title='Payment Status', bbox_to_anchor=(1.05, 1))
        ax.grid(axis='y', alpha=0.3)
        
        plt.tight_layout()
        if save_path:
            plt.savefig(save_path, dpi=300, bbox_inches='tight')
        plt.show()
    
    def generate_insights_report(self):
        """Generate comprehensive insights report"""
        print("\n" + "="*60)
        print("KEY INSIGHTS REPORT")
        print("="*60)
        
        # Overall statistics
        print("\n1. OVERALL PORTFOLIO HEALTH")
        print("-" * 40)
        total_customers = len(self.df)
        delinquent_count = self.df['delinquent_account'].sum()
        delinquency_rate = (delinquent_count / total_customers) * 100
        
        print(f"Total Customers: {total_customers:,}")
        print(f"Delinquent Accounts: {delinquent_count:,}")
        print(f"Delinquency Rate: {delinquency_rate:.2f}%")
        print(f"Average Risk Score: {self.df['risk_score'].mean():.3f}")
        
        # Risk tier breakdown
        print("\n2. RISK TIER DISTRIBUTION")
        print("-" * 40)
        risk_dist = self.df['risk_tier'].value_counts()
        for tier in ['HIGH', 'MEDIUM', 'LOW']:
            if tier in risk_dist:
                count = risk_dist[tier]
                pct = (count / total_customers) * 100
                print(f"{tier}: {count:,} customers ({pct:.1f}%)")
        
        # High-risk characteristics
        print("\n3. HIGH-RISK CUSTOMER PROFILE")
        print("-" * 40)
        high_risk = self.df[self.df['risk_tier'] == 'HIGH']
        print(f"Average Income: ${high_risk['income'].mean():,.0f}")
        print(f"Average Credit Score: {high_risk['credit_score'].mean():.0f}")
        print(f"Average Credit Utilization: {high_risk['credit_utilization'].mean():.2%}")
        print(f"Average Missed Payments: {high_risk['missed_payments'].mean():.1f}")
        print(f"Average DTI Ratio: {high_risk['debt_to_income_ratio'].mean():.2%}")
        
        # Employment impact
        print("\n4. EMPLOYMENT STATUS IMPACT")
        print("-" * 40)
        emp_risk = self.df.groupby('employment_status').agg({
            'risk_score': 'mean',
            'delinquent_account': 'sum',
            'customer_id': 'count'
        }).round(3)
        emp_risk.columns = ['Avg Risk Score', 'Delinquent Count', 'Total Customers']
        emp_risk['Delinquency Rate %'] = (emp_risk['Delinquent Count'] / 
                                          emp_risk['Total Customers'] * 100).round(2)
        print(emp_risk.sort_values('Avg Risk Score', ascending=False))
        
        # Income impact
        print("\n5. INCOME LEVEL IMPACT")
        print("-" * 40)
        self.df['income_bracket'] = pd.cut(
            self.df['income'],
            bins=[0, 30000, 80000, 150000, float('inf')],
            labels=['<30K', '30K-80K', '80K-150K', '>150K']
        )
        income_risk = self.df.groupby('income_bracket').agg({
            'risk_score': 'mean',
            'delinquent_account': 'sum',
            'customer_id': 'count'
        }).round(3)
        income_risk.columns = ['Avg Risk Score', 'Delinquent Count', 'Total Customers']
        income_risk['Delinquency Rate %'] = (income_risk['Delinquent Count'] / 
                                             income_risk['Total Customers'] * 100).round(2)
        print(income_risk)
        
        # Key risk drivers
        print("\n6. TOP RISK DRIVERS (Correlation with Delinquency)")
        print("-" * 40)
        correlations = self.df[['missed_payments', 'credit_utilization', 
                               'credit_score', 'debt_to_income_ratio', 
                               'delinquent_account']].corr()['delinquent_account'].sort_values(ascending=False)
        print(correlations[1:])  # Exclude self-correlation
        
        print("\n" + "="*60)


def main():
    """
    Main execution function
    Usage example with PostgreSQL
    """
    # Database connection string - UPDATE WITH YOUR CREDENTIALS
    # Format: 'postgresql://username:password@host:port/database'
    connection_string = 'postgresql://user:password@localhost:5432/banking_analytics'
    
    # Initialize EDA
    print("Banking Delinquency Analysis - Starting EDA")
    print("=" * 60)
    
    eda = BankingDelinquencyEDA(connection_string)
    
    # Load data
    print("\n1. Loading data...")
    eda.load_data()
    
    # Data overview
    print("\n2. Generating data overview...")
    eda.data_overview()
    
    # Calculate risk scores
    print("\n3. Calculating risk scores...")
    eda.calculate_risk_score()
    
    # Generate visualizations
    print("\n4. Generating visualizations...")
    eda.plot_risk_distribution(save_path='../images/risk_distribution.png')
    eda.plot_feature_correlation(save_path='../images/feature_correlation.png')
    eda.plot_risk_by_demographics(save_path='../images/risk_by_demographics.png')
    eda.plot_payment_patterns(save_path='../images/payment_patterns.png')
    
    # Generate insights report
    print("\n5. Generating insights report...")
    eda.generate_insights_report()
    
    print("\n" + "="*60)
    print("EDA COMPLETED SUCCESSFULLY!")
    print("="*60)


if __name__ == "__main__":
    main()
