"""
Product Analytics Data Generator
Generates realistic event-based user data for funnel, campaign, and retention analysis
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

# Set random seed for reproducibility
np.random.seed(42)
random.seed(42)

# Configuration
NUM_USERS = 10000
START_DATE = datetime(2025, 7, 1)
END_DATE = datetime(2025, 12, 31)

print("🚀 Starting data generation for Product Analytics project...")
print(f"📊 Generating data for {NUM_USERS} users from {START_DATE.date()} to {END_DATE.date()}")

# ============================================
# 1. CAMPAIGNS TABLE
# ============================================
print("\n📢 Creating campaigns table...")

campaigns = pd.DataFrame({
    'campaign_id': [1, 2, 3, 4, 5, 6, 7, 8],
    'campaign_name': [
        'Google Search - Brand',
        'Google Search - Generic',
        'Facebook Ads - Retargeting',
        'Instagram Influencer',
        'Email Newsletter',
        'Organic Search',
        'Direct Traffic',
        'YouTube Ads'
    ],
    'channel': [
        'Google Ads',
        'Google Ads',
        'Facebook',
        'Instagram',
        'Email',
        'Organic',
        'Direct',
        'YouTube'
    ],
    'cost': [15000, 25000, 18000, 30000, 5000, 0, 0, 22000]  # Monthly cost in USD
})

print(f"✅ Created {len(campaigns)} campaigns")

# ============================================
# 2. USERS TABLE
# ============================================
print("\n👥 Creating users table...")

# Generate signup dates (more recent signups)
signup_dates = []
for _ in range(NUM_USERS):
    days_diff = (END_DATE - START_DATE).days
    random_days = int(np.random.exponential(scale=days_diff/3))
    random_days = min(random_days, days_diff)
    signup_date = START_DATE + timedelta(days=random_days)
    signup_dates.append(signup_date)

# Campaign distribution (weighted - some campaigns bring more users)
campaign_weights = [0.15, 0.20, 0.12, 0.08, 0.10, 0.25, 0.05, 0.05]
acquisition_sources = random.choices(campaigns['campaign_id'].tolist(), weights=campaign_weights, k=NUM_USERS)

users = pd.DataFrame({
    'user_id': range(1, NUM_USERS + 1),
    'signup_date': signup_dates,
    'device': np.random.choice(['mobile', 'desktop', 'tablet'], NUM_USERS, p=[0.60, 0.35, 0.05]),
    'country': np.random.choice(['USA', 'UK', 'Canada', 'India', 'Australia'], NUM_USERS, p=[0.45, 0.20, 0.15, 0.12, 0.08]),
    'acquisition_source': acquisition_sources
})

print(f"✅ Created {len(users)} users")

# ============================================
# 3. EVENTS TABLE
# ============================================
print("\n🎯 Creating events table...")

events_list = []

# Event probabilities vary by campaign quality
campaign_conversion_quality = {
    1: {'visit_to_cart': 0.65, 'cart_to_purchase': 0.50},  # Google Brand - high intent
    2: {'visit_to_cart': 0.55, 'cart_to_purchase': 0.35},  # Google Generic
    3: {'visit_to_cart': 0.70, 'cart_to_purchase': 0.45},  # Facebook Retargeting - high quality
    4: {'visit_to_cart': 0.45, 'cart_to_purchase': 0.25},  # Instagram Influencer - low conversion
    5: {'visit_to_cart': 0.60, 'cart_to_purchase': 0.40},  # Email
    6: {'visit_to_cart': 0.58, 'cart_to_purchase': 0.38},  # Organic
    7: {'visit_to_cart': 0.68, 'cart_to_purchase': 0.48},  # Direct - high intent
    8: {'visit_to_cart': 0.50, 'cart_to_purchase': 0.30},  # YouTube
}

product_categories = ['Electronics', 'Clothing', 'Home & Garden', 'Sports', 'Books']
product_prices = {
    'Electronics': (50, 500),
    'Clothing': (20, 150),
    'Home & Garden': (30, 300),
    'Sports': (25, 200),
    'Books': (10, 50)
}

for idx, user in users.iterrows():
    user_id = user['user_id']
    signup_date = user['signup_date']
    campaign_id = user['acquisition_source']
    
    # Get campaign-specific conversion rates
    visit_to_cart_prob = campaign_conversion_quality[campaign_id]['visit_to_cart']
    cart_to_purchase_prob = campaign_conversion_quality[campaign_id]['cart_to_purchase']
    
    # Determine how many sessions this user will have (1-5 sessions)
    num_sessions = np.random.choice([1, 2, 3, 4, 5], p=[0.40, 0.30, 0.15, 0.10, 0.05])
    
    for session in range(num_sessions):
        # Session date (after signup, within data range)
        days_after_signup = int(np.random.exponential(scale=15))
        event_date = signup_date + timedelta(days=days_after_signup)
        
        if event_date > END_DATE:
            event_date = END_DATE
        
        # Every session starts with a visit
        events_list.append({
            'user_id': user_id,
            'event_date': event_date,
            'event_name': 'visit',
            'product_id': None,
            'campaign_id': campaign_id,
            'revenue': 0
        })
        
        # Add to cart?
        if random.random() < visit_to_cart_prob:
            product_category = random.choice(product_categories)
            product_id = f"{product_category}_{random.randint(1, 100)}"
            
            events_list.append({
                'user_id': user_id,
                'event_date': event_date + timedelta(minutes=random.randint(1, 30)),
                'event_name': 'add_to_cart',
                'product_id': product_id,
                'campaign_id': campaign_id,
                'revenue': 0
            })
            
            # Purchase?
            if random.random() < cart_to_purchase_prob:
                price_range = product_prices[product_category]
                revenue = round(random.uniform(price_range[0], price_range[1]), 2)
                
                events_list.append({
                    'user_id': user_id,
                    'event_date': event_date + timedelta(minutes=random.randint(31, 60)),
                    'event_name': 'purchase',
                    'product_id': product_id,
                    'campaign_id': campaign_id,
                    'revenue': revenue
                })

events = pd.DataFrame(events_list)
events = events.sort_values(['user_id', 'event_date']).reset_index(drop=True)
events['event_id'] = range(1, len(events) + 1)

# Reorder columns
events = events[['event_id', 'user_id', 'event_date', 'event_name', 'product_id', 'campaign_id', 'revenue']]

print(f"✅ Created {len(events)} events")
print(f"   - Visits: {len(events[events['event_name'] == 'visit'])}")
print(f"   - Add to Cart: {len(events[events['event_name'] == 'add_to_cart'])}")
print(f"   - Purchases: {len(events[events['event_name'] == 'purchase'])}")

# ============================================
# 4. SAVE TO CSV
# ============================================
print("\n💾 Saving data to CSV files...")

campaigns.to_csv('../data/campaigns.csv', index=False)
users.to_csv('../data/users.csv', index=False)
events.to_csv('../data/events.csv', index=False)

print("✅ Saved campaigns.csv")
print("✅ Saved users.csv")
print("✅ Saved events.csv")

# ============================================
# 5. SUMMARY STATISTICS
# ============================================
print("\n" + "="*60)
print("📈 DATA GENERATION SUMMARY")
print("="*60)

print(f"\n👥 USERS:")
print(f"   Total Users: {len(users):,}")
print(f"   Date Range: {users['signup_date'].min().date()} to {users['signup_date'].max().date()}")
print(f"   Devices: Mobile={len(users[users['device']=='mobile'])}, Desktop={len(users[users['device']=='desktop'])}, Tablet={len(users[users['device']=='tablet'])}")

print(f"\n🎯 EVENTS:")
print(f"   Total Events: {len(events):,}")
print(f"   Avg Events per User: {len(events)/len(users):.1f}")

print(f"\n📊 FUNNEL METRICS:")
total_visits = len(events[events['event_name'] == 'visit'])
total_carts = len(events[events['event_name'] == 'add_to_cart'])
total_purchases = len(events[events['event_name'] == 'purchase'])

print(f"   Visits: {total_visits:,}")
print(f"   Add to Cart: {total_carts:,} ({total_carts/total_visits*100:.1f}% of visits)")
print(f"   Purchases: {total_purchases:,} ({total_purchases/total_carts*100:.1f}% of carts)")
print(f"   Overall Conversion: {total_purchases/total_visits*100:.1f}%")

print(f"\n💰 REVENUE:")
total_revenue = events[events['event_name'] == 'purchase']['revenue'].sum()
avg_order_value = events[events['event_name'] == 'purchase']['revenue'].mean()
print(f"   Total Revenue: ${total_revenue:,.2f}")
print(f"   Average Order Value: ${avg_order_value:.2f}")
print(f"   Total Marketing Cost: ${campaigns['cost'].sum():,}")
print(f"   ROI: {(total_revenue / campaigns['cost'].sum() - 1) * 100:.1f}%")

print("\n" + "="*60)
print("✅ DATA GENERATION COMPLETE!")
print("="*60)
print("\n📁 Files created in ../data/ directory")
print("🎯 Ready for SQL analysis and Power BI visualization")
