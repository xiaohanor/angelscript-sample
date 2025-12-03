class USkylineDroneBossBeamOrbitCapability : USkylineDroneBossChildCapability
{
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossAttack);
	default CapabilityTags.Add(SkylineDroneBossTags::SkylineDroneBossBeam);

	ASkylineDroneBossBeamRing Ring;
	ASkylineDroneBossBeamRing TempRing;

	USkylineDroneBossBeamPhase BeamPhase;

	float OrbitAngle = 0.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Boss.HasAnyAttachments())
			return false;

		if (Boss.CurrentPhase == nullptr)
			return false;

		auto Phase = Cast<USkylineDroneBossBeamPhase>(Boss.CurrentPhase);
		if (Phase == nullptr)
			return false;

		float TimeSinceAttach = Time::GetGameTimeSince(Boss.PhaseStartTimestamp);
		if (TimeSinceAttach < Phase.RingActivationDelay)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Boss.HasAnyAttachments())
			return true;

		if (Boss.CurrentPhase == nullptr)
			return true;

		auto Phase = Cast<USkylineDroneBossBeamPhase>(Boss.CurrentPhase);
		if (Phase == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BeamPhase = Cast<USkylineDroneBossBeamPhase>(Boss.CurrentPhase);
		
		OrbitAngle = 0.0;

		auto& LeftAttachment = Boss.LeftAttachment;
		if (LeftAttachment.IsValid())
		{
			auto LeftBeamAttachment = Cast<ASkylineDroneBossBeamAttachment>(LeftAttachment.Actor);

			if (LeftBeamAttachment != nullptr && BeamPhase.RingType != nullptr)
			{
				Ring = Cast<ASkylineDroneBossBeamRing>(
					SpawnActor(BeamPhase.RingType)
				);
				Ring.AttachToComponent(Boss.BodyMesh);
			}
		}

		auto& RightAttachment = Boss.RightAttachment;
		if (RightAttachment.IsValid())
		{
			auto RightBeamAttachment = Cast<ASkylineDroneBossBeamAttachment>(RightAttachment.Actor);

			if (RightBeamAttachment != nullptr && BeamPhase.RingType != nullptr)
			{
				TempRing = Cast<ASkylineDroneBossBeamRing>(
					SpawnActor(BeamPhase.RingType)
				);
				TempRing.AttachToComponent(Boss.BodyMesh);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (Ring != nullptr)
		{
			Ring.DestroyActor();
		}

		if (TempRing != nullptr)
		{
			TempRing.DestroyActor();
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		OrbitAngle += BeamPhase.OrbitSpeed * DeltaTime;

		FVector UpVector = Boss.BodyMesh.UpVector;
		FVector ForwardVector = Boss.BodyMesh.ForwardVector;

		FVector OrbitAxis = ForwardVector;
		float OrbitRadius = Boss.LeftPivot.RelativeLocation.Size();
		FVector OrbitDirection = OrbitAxis.RotateAngleAxis(OrbitAngle - 90, UpVector);

		FVector TempOrbitAxis = Boss.BodyMesh.RightVector;
		FVector TempOrbitDirection = TempOrbitAxis.RotateAngleAxis(OrbitAngle + 180, ForwardVector);

		auto& LeftAttachment = Boss.LeftAttachment;
		if (LeftAttachment.IsValid())
		{
			FRotator LeftRotation = FRotator::MakeFromZX(OrbitDirection.GetSafeNormal(), UpVector);
			LeftAttachment.Actor.SetActorLocationAndRotation(
				Boss.BodyMesh.WorldLocation + OrbitDirection * OrbitRadius,
				LeftRotation
			);

			if (Ring != nullptr)
			{
				FVector TestUpVector = UpVector.RotateAngleAxis(OrbitAngle * 3.0, OrbitDirection.GetSafeNormal());
				FRotator RingRotation = FRotator::MakeFromXY(OrbitDirection.GetSafeNormal(), TestUpVector);
				
				Ring.SetActorLocationAndRotation(
					Boss.BodyPivot.WorldLocation,
					RingRotation
				);
			}
		}

		auto& RightAttachment = Boss.RightAttachment;
		if (RightAttachment.IsValid())
		{
			FRotator RightRotation = FRotator::MakeFromZX(-TempOrbitDirection.GetSafeNormal(), UpVector);
			RightAttachment.Actor.SetActorLocationAndRotation(
				Boss.BodyMesh.WorldLocation - TempOrbitDirection * OrbitRadius,
				RightRotation
			);

			if (TempRing != nullptr)
			{
				FVector TestUpVector = UpVector.RotateAngleAxis(OrbitAngle * 2.0, TempOrbitDirection.GetSafeNormal());
				FRotator RingRotation = FRotator::MakeFromXY(TempOrbitDirection.GetSafeNormal(), TestUpVector);
				
				TempRing.SetActorLocationAndRotation(
					Boss.BodyPivot.WorldLocation,
					RingRotation
				);
			}
		}
	}
}