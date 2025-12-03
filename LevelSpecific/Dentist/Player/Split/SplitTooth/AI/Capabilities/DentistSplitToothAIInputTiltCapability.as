class UDentistSplitToothAIInputTiltCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::SplitTooth::SplitToothTag);

	default TickGroup = EHazeTickGroup::Input;

	ADentistSplitToothAI SplitToothAI;

	UHazeMovementComponent MoveComp;
	UHazeCrumbSyncedVectorComponent SyncedTiltAmount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplitToothAI = Cast<ADentistSplitToothAI>(Owner);
		MoveComp = SplitToothAI.MoveComp;
		SyncedTiltAmount = SplitToothAI.SyncedTiltAmount;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SplitToothAI.AccTiltAmount.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SplitToothAI.AccTiltAmount.SnapTo(FVector::UpVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(!MoveComp.MovementInput.IsNearlyZero())
			{
				FVector RightVector = FVector::UpVector.CrossProduct(MoveComp.MovementInput).GetSafeNormal();
				float TiltAmount = MoveComp.MovementInput.Size() * SplitToothAI.Settings.MaxIdleInput;
				SplitToothAI.AccTiltAmount.AccelerateTo(FQuat(RightVector, TiltAmount).UpVector, SplitToothAI.Settings.InputAccelerateDuration, DeltaTime);
			}
			else
			{
				SplitToothAI.AccTiltAmount.AccelerateTo(FVector::UpVector, SplitToothAI.Settings.InputAccelerateDuration, DeltaTime);
			}

			SyncedTiltAmount.SetValue(SplitToothAI.AccTiltAmount.Value);
		}
		else
		{
			SplitToothAI.AccTiltAmount.AccelerateTo(SyncedTiltAmount.Value, 0.2, DeltaTime);
		}
	}
};