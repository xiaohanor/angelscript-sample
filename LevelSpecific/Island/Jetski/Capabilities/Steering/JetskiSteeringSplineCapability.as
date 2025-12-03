class UJetskiSteeringSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

    default TickGroup = EHazeTickGroup::Input;
    default TickGroupOrder = 100;

    AJetski Jetski;

    UFUNCTION(BlueprintOverride)
    void Setup()
    {
        Jetski = Cast<AJetski>(Owner);
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldActivate() const
    {
		if(Jetski.Settings.SteeringMode != EJetskiSteeringMode::Spline)
			return false;

        return true;
    }

    UFUNCTION(BlueprintOverride)
    bool ShouldDeactivate() const
    {
		if(Jetski.Settings.SteeringMode != EJetskiSteeringMode::Spline)
			return true;

        return false;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		float Steering = Jetski.Input.GetSteering();
		bool bIsInputting = Math::Abs(Steering) > 0.2;

        if(bIsInputting)
		{
			if(Jetski.Settings.bSplineClamp)
			{
				const float SplineWidth = Jetski.GetSplineWidth();
				const float SideDistance = Jetski.GetSideDistance(bAbsolute = false);
				const float OuterMarginDistance = SplineWidth * Jetski.Settings.SplineClampOuterMarginPercentage;
				const float InnerMarginDistance = SplineWidth * Jetski.Settings.SplineClampInnerMarginPercentage;

				if(Math::Abs(SideDistance) > InnerMarginDistance)
				{
					const bool bIsSteeringRight = Jetski.AccSteering.Value > 0;
					const bool bMarginIsToRight = SideDistance > 0;
					const bool bIsInputtingRight = Steering > 0;

					const bool bShouldClamp = (bIsSteeringRight && bMarginIsToRight && bIsInputtingRight) || (!bIsSteeringRight && !bMarginIsToRight && !bIsInputtingRight);

					if(bShouldClamp)
					{
						const float MarginFactor = Math::Saturate(Math::NormalizeToRange(Math::Abs(SideDistance), InnerMarginDistance, OuterMarginDistance));
						Steering = Math::Lerp(Steering, 0, MarginFactor);
						
						float Duration = Math::Lerp(Jetski.Settings.SteeringDuration, 0.05, Math::EaseOut(0, 1, MarginFactor, 2));

						Jetski.AccSteering.AccelerateTo(Steering, Duration, DeltaTime);
						return;
					}
					
				}
			}

        	Jetski.AccSteering.AccelerateTo(Steering, Jetski.Settings.SteeringDuration, DeltaTime);
		}
		else
		{
        	Jetski.AccSteering.AccelerateTo(0, Jetski.Settings.SteeringReturnDuration, DeltaTime);
		}
    }
}