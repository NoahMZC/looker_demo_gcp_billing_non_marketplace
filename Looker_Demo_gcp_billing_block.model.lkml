connection: "@{CONNECTION}"
label: "Google Cloud Billing"

include: "/views/*.view.lkml"
include: "/dashboards/*"
include: "/explores/*.explore.lkml"

datagroup:billing_datagroup {
  sql_trigger: select max(export_time) from`@{BILLING_TABLE}`;;
  description: "Triggers a rebuild when new data is exported"
}

datagroup:pricing_datagroup {
  sql_trigger: select max(export_time) from `@{PRICING_TABLE}`;;
  description: "Triggers a rebuild when new data is exported"
}

view: +gcp_billing_export {
  dimension: first_date_in_period {
    datatype: date
  }
  dimension: first_date_in_prior_period {
    datatype: date
  }
  dimension: last_date_in_prior_period {
    datatype: date
  }
}

view: +recommendations_export {

  dimension_group: _partitiondate {
    hidden: yes
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    # sql: ${TABLE}._PARTITIONDATE ;;
    sql: DATE_ADD(${TABLE}._PARTITIONDATE,
                    INTERVAL (DATE_DIFF(CURRENT_DATE,'2021-07-20',DAY)) DAY) ;;
  }

  dimension_group: _partitiontime {
    hidden: yes
    type: time
    timeframes: [
      raw,
      date,
      week,
      month,
      quarter,
      year
    ]
    convert_tz: no
    datatype: date
    # sql: ${TABLE}._PARTITIONTIME ;;
    sql: TIMESTAMP_ADD(${TABLE}._PARTITIONTIME, INTERVAL (DATE_DIFF(CURRENT_DATE,'2021-07-20',DAY)) DAY) ;;
  }

  dimension_group: last_refresh {
    type: time
    description: "Output only. Last time this recommendation was refreshed by the system that created it in the first place."
    timeframes: [
      raw,
      time,
      date,
      week,
      month,
      quarter,
      year
    ]
    # sql: ${TABLE}.last_refresh_time ;;
    sql: TIMESTAMP_ADD(${TABLE}.last_refresh_time, INTERVAL (DATE_DIFF(CURRENT_DATE,'2021-07-20',DAY)) DAY) ;;
  }

}


  explore: +recommendations_export {
    label: "Recommendations"
    sql_always_where:
    -- Show only the latest recommendations. Use a grace period of 3 days to avoid data export gaps.
      ${_partitiondate_date} = DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
      AND ${cloud_entity_type} = 'PROJECT_NUMBER'
      AND ${state} = 'ACTIVE'
      AND ${recommender} IN ('google.compute.commitment.UsageCommitmentRecommender',
       'google.compute.disk.IdleResourceRecommender',
        'google.compute.instance.IdleResourceRecommender',
       'google.compute.instance.MachineTypeRecommender' )
      AND ${primary_impact__cost_projection__cost__units} IS NOT NULL ;;
  }
