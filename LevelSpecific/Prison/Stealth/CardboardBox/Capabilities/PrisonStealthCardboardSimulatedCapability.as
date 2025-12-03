struct FPrisonStealthCardboardSimulatedActivateParams
{
	FVector Impulse;
};

struct FPrisonStealthCardboardSimulatedDeactivateParams
{
	bool bRespawn = false;
};

class UPrisonStealthCardboardSimulatedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	APrisonStealthCardboardBox CardboardBox;

	const float AngularImpulse = 50000;
	const float SimulateDuration = 3.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CardboardBox = Cast<APrisonStealthCardboardBox>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonStealthCardboardSimulatedActivateParams& Params) const
	{
		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Simulating)
			return false;

		Params.Impulse = CardboardBox.InitialImpulse;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FPrisonStealthCardboardSimulatedDeactivateParams& Params) const
	{
		if(CardboardBox.DesiredState != EPrisonStealthCardboardBoxState::Simulating)
			return true;

		if(CardboardBox.CurrentState != EPrisonStealthCardboardBoxState::Simulating)
			return true;

		if(ActiveDuration > SimulateDuration)
		{
			Params.bRespawn = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonStealthCardboardSimulatedActivateParams Params)
	{
		CardboardBox.ApplyState(EPrisonStealthCardboardBoxState::Simulating);

		if(!Params.Impulse.IsNearlyZero())
		{
			CardboardBox.MeshComp.AddImpulse(Params.Impulse);
			FVector AngularImpulseDirection = FVector::UpVector.CrossProduct(Params.Impulse).GetSafeNormal();
			CardboardBox.MeshComp.AddAngularImpulseInRadians(AngularImpulseDirection * AngularImpulse);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FPrisonStealthCardboardSimulatedDeactivateParams Params)
	{
		if(Params.bRespawn)
			CardboardBox.DesiredState = EPrisonStealthCardboardBoxState::Respawn;
	}
};