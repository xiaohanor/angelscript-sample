struct FGravityBikeSplineAutoAimData
{
	UPROPERTY()
	bool bOnlyWhileAirborne = true;

	UPROPERTY()
	float SteeringFraction = 1.0;

	UPROPERTY()
	float AutoAimStrength = 3;

	UPROPERTY()
	float TimeToReachFullAutoAim = 1;

	UPROPERTY()
	float TimeToReachNoAutoAim = 0.2;
}

class UGravityBikeSplineAutoAimCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(GravityBikeSpline::MovementTags::GravityBikeSplineMovement);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	AGravityBikeSplineActor AutoAimSpline;
	bool bAutoAimingFromLeft = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UGravityBikeSplineMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GravityBike.AutoAim.IsDefaultValue())
			return false;

		if(GravityBike.AutoAim.Get().bOnlyWhileAirborne)
		{
			if(!GravityBike.IsAirborne.Get())
				return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.AutoAim.IsDefaultValue())
			return true;

		if(GravityBike.AutoAim.Get().bOnlyWhileAirborne)
		{
			if(!GravityBike.IsAirborne.Get())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.bIsAutoAiming = true;
		AutoAimSpline = GravityBike.GetActiveSplineActor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.bIsAutoAiming = false;

		if(!GravityBike.IsAirborne.Get())
			GravityBike.AutoAimAlpha = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//PrintToScreen(f"AUTO AIM! {GravityBike.AutoAim.CurrentInstigator}, {GravityBike.AutoAim.CurrentPriority}");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActive())
		{
			if(GravityBike.AutoAim.Get().TimeToReachFullAutoAim < KINDA_SMALL_NUMBER)
				GravityBike.AutoAimAlpha = 1;
			else
				GravityBike.AutoAimAlpha = Math::FInterpConstantTo(GravityBike.AutoAimAlpha, 1.0, DeltaTime, 1.0 / GravityBike.AutoAim.Get().TimeToReachFullAutoAim);
		}
		else if(IsBlocked())
		{
			GravityBike.AutoAimAlpha = 0;
		}
		else
		{
			if(GravityBike.AutoAim.Get().TimeToReachNoAutoAim < KINDA_SMALL_NUMBER)
				GravityBike.AutoAimAlpha = 0;
			else
				GravityBike.AutoAimAlpha = Math::FInterpConstantTo(GravityBike.AutoAimAlpha, 0.0, DeltaTime, 1.0 / GravityBike.AutoAim.Get().TimeToReachNoAutoAim);
		}
	}
};