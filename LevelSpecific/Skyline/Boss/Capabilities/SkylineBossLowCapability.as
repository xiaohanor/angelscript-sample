class USkylineBossLowCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossFall);

	FVector StartLocation;
	FQuat StartRotation;

	FVector TargetLocation;
	FQuat TargetRotation;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.IsStateActive(ESkylineBossState::Down))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration >= 5.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
//		Owner.BlockCapabilities(SkylineBossTags::SkylineBossLookAt, this);
		Owner.BlockCapabilities(SkylineBossTags::SkylineBossForceField, this);

		PrintToScreenScaled("Low!", 3.0, FLinearColor::Yellow, 3.0);

		StartLocation = Boss.ActorLocation;
		StartRotation = Boss.HeadPivot.ComponentQuat;

		TargetLocation = Boss.CurrentHub.ActorLocation + Boss.CurrentHub.ActorUpVector * 2000.0;
		TargetRotation = FQuat::MakeFromZX(Boss.CurrentHub.ActorUpVector.RotateAngleAxis(-14.0,  Boss.CurrentHub.ActorRightVector), Boss.CurrentHub.ActorForwardVector);

	//	Debug::DrawDebugCoordinateSystem(HitResult.ImpactPoint, TargetRotation.Rotator(), 3000.0, 500.0, 10.0);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
//		Owner.UnblockCapabilities(SkylineBossTags::SkylineBossLookAt, this);
		Owner.UnblockCapabilities(SkylineBossTags::SkylineBossForceField, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			float Alpha = Math::Min(1.0, ActiveDuration / 5.0);

			Boss.SetActorLocation(Math::Lerp(StartLocation, TargetLocation, Alpha));
	//		Boss.HeadPivot.SetWorldRotation(FQuat::Slerp(StartRotation, TargetRotation, Alpha));


			FVector LookAtDirection = Boss.HeadPivot.ForwardVector;
			if (Boss.GetDistanceTo(Boss.LookAtTarget.Get()) > 500.0)
				LookAtDirection = (Boss.LookAtTarget.Get().ActorLocation - Boss.HeadPivot.WorldLocation).GetSafeNormal();

			FVector Torque = Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.ForwardVector.CrossProduct(LookAtDirection) * Boss.Settings.LookAtSpeed)
						+ Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.UpVector.CrossProduct(FVector::UpVector) * Boss.Settings.LookAtSpeed * 0.2)
						- Boss.AngularVelocity * Boss.Settings.LookAtDrag;

			Boss.AngularVelocity += Torque * DeltaTime;

			FRotator Rotation = (Boss.HeadPivot.ComponentQuat * FQuat(Boss.AngularVelocity.SafeNormal, Boss.AngularVelocity.Size() * DeltaTime)).Rotator();
			Rotation.Pitch = Math::Max(-30.0, Rotation.Pitch);
			Rotation.Roll = 0.0;

			Boss.HeadPivot.SetWorldRotation(Rotation);
		}
		else
		{
			ApplyCrumbSyncedPosition();
			ApplyCrumbSyncedHeadPivotRotation();
		}
	}
}