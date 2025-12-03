struct FGravityBikeSplineAttackShipOpenHatchDeactivateParams
{
	bool bNatural = false;
};

class UGravityBikeSplineAttackShipOpenHatchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AGravityBikeSplineAttackShip AttackShip;

	float OpenAlpha = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<AGravityBikeSplineAttackShip>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!ShouldOpen())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeSplineAttackShipOpenHatchDeactivateParams& Params) const
	{
		// Wait until we have fully closed
		if(!IsClosed())
			return false;

		if(!ShouldOpen())
		{
			Params.bNatural = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(IsClosed())
		{
			UGravityBikeSplineAttackShipEventHandler::Trigger_OnOpenHatchStart(AttackShip);
			AttackShip.OnHatchStartOpening();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeSplineAttackShipOpenHatchDeactivateParams Params)
	{
		if(Params.bNatural)
			UGravityBikeSplineAttackShipEventHandler::Trigger_OnCloseHatchFinished(AttackShip);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(IsFullyOpen() && ShouldOpen())
		{
			// All is well
			return;
		}

		if(ShouldOpen())
		{
			OpenAlpha = Math::FInterpConstantTo(OpenAlpha, 1, DeltaTime, 1 / AttackShip.OpenDuration);

			if(IsFullyOpen())
			{
				// We opened fully
				UGravityBikeSplineAttackShipEventHandler::Trigger_OnOpenHatchFinished(AttackShip);
			}
		}
		if(!ShouldOpen())
		{
			if(IsFullyOpen())
			{
				// We just started closing
				UGravityBikeSplineAttackShipEventHandler::Trigger_OnCloseHatchStart(AttackShip);
			}

			OpenAlpha = Math::FInterpConstantTo(OpenAlpha, 0, DeltaTime, 1 / AttackShip.CloseDuration);
		}

		AttackShip.HatchMeshComp.SetRelativeRotation(FRotator(AttackShip.OpenHatchAngle * OpenAlpha, 0, 0));
	}

	bool ShouldOpen() const
	{
		return !AttackShip.OpenHatchInstigators.IsEmpty();
	}

	bool IsClosed() const
	{
		return OpenAlpha < KINDA_SMALL_NUMBER;
	}

	bool IsFullyOpen() const
	{
		return OpenAlpha > 1.0 - KINDA_SMALL_NUMBER;
	}
};