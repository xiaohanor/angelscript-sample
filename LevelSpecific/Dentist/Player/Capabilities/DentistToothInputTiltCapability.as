class UDentistToothInputTiltCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Input;

	UDentistToothPlayerComponent PlayerComp;

	UPlayerMovementComponent MoveComp;
	UHazeCrumbSyncedVectorComponent SyncedTiltAmount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		SyncedTiltAmount = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"SyncedTiltAmount");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Dentist::bApplyInputTilt)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Dentist::bApplyInputTilt)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.AccTiltAmount.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.AccTiltAmount.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(!MoveComp.MovementInput.IsNearlyZero())
			{
				FVector RightVector = FVector::UpVector.CrossProduct(MoveComp.MovementInput).GetSafeNormal();
				float TiltAmount = MoveComp.MovementInput.Size() * 0.5;
				PlayerComp.AccTiltAmount.AccelerateTo(FQuat(RightVector, TiltAmount).UpVector, 0.5, DeltaTime);
			}
			else
			{
				PlayerComp.AccTiltAmount.AccelerateTo(FVector::UpVector, 0.5, DeltaTime);
			}

			SyncedTiltAmount.SetValue(PlayerComp.AccTiltAmount.Value);
		}
		else
		{
			PlayerComp.AccTiltAmount.AccelerateTo(SyncedTiltAmount.Value, 0.2, DeltaTime);
		}
	}
};