class USkylineBossLookAtCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossLookAt);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Boss.LookAtTarget.Get() == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Boss.LookAtTarget.Get() == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector LookAtDirection = Boss.HeadPivot.ForwardVector;
			if (Boss.GetSquaredDistanceTo(Boss.LookAtTarget.Get()) > Math::Square(Boss.Settings.MinLongRangeAttacks))
				LookAtDirection = (Boss.LookAtTarget.Get().ActorLocation - Boss.HeadPivot.WorldLocation).GetSafeNormal();

			FVector Torque = Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.ForwardVector.CrossProduct(LookAtDirection) * Boss.Settings.LookAtSpeed)
						+ Boss.HeadPivot.WorldTransform.InverseTransformVectorNoScale(Boss.HeadPivot.UpVector.CrossProduct(FVector::UpVector) * Boss.Settings.LookAtSpeed * 0.2)
						- Boss.AngularVelocity * Boss.Settings.LookAtDrag;

			Boss.AngularVelocity += Torque * DeltaTime;

			FRotator Rotation = (Boss.HeadPivot.ComponentQuat * FQuat(Boss.AngularVelocity.SafeNormal, Boss.AngularVelocity.Size() * DeltaTime)).Rotator();
			Rotation.Pitch = Math::Max(-45.0, Rotation.Pitch);
			Rotation.Roll = 0.0;

			Boss.HeadPivot.SetWorldRotation(Rotation);
		}
		else
		{
			ApplyCrumbSyncedHeadPivotRotation();
		}
	}
}