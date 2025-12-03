class USkylineCrowdSurfingUserComponent : UActorComponent
{
	UPROPERTY()
	UAnimSequence SurfAnim;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	float MovementForce = 800.0;

	UPROPERTY()
	float CrowdPushForce = 4000.0;

	bool IsCrowdSurfing = false;

	UPROPERTY()
	float CrowdDrag = 3.0;

	bool IsInCrowd() const
	{
		int ActiveCrowdVolumes = 0;

		TListedActors<ASkylineCrowdSurfingVolume> CrowdSurfingVolumes;
		for (auto CrowdSurfingVolume : CrowdSurfingVolumes)
		{
			if (Shape::IsPointInside(CrowdSurfingVolume.Shape.CollisionShape, CrowdSurfingVolume.ActorTransform, Owner.ActorLocation))
				ActiveCrowdVolumes++;
		}

		return (ActiveCrowdVolumes > 0 ? true : false);
	}

	bool HasLeftCrowd() const
	{
		int ActiveCrowdVolumes = 0;

		TListedActors<ASkylineCrowdSurfingVolume> CrowdSurfingVolumes;
		for (auto CrowdSurfingVolume : CrowdSurfingVolumes)
		{
			if (Shape::IsPointInside(CrowdSurfingVolume.Shape.CollisionShape, CrowdSurfingVolume.ActorTransform, Owner.ActorLocation - FVector::UpVector * 100.0))
				ActiveCrowdVolumes++;
		}

		return (ActiveCrowdVolumes > 0 ? false : true);
	}

	FVector GetPushForce() property
	{
		int ActiveCrowdVolumes = 0;
		FVector Force;

		TListedActors<ASkylineCrowdSurfingVolume> CrowdSurfingVolumes;
		for (auto CrowdSurfingVolume : CrowdSurfingVolumes)
		{
			if (Shape::IsPointInside(CrowdSurfingVolume.Shape.CollisionShape, CrowdSurfingVolume.ActorTransform, Owner.ActorLocation))
			{
				FVector ToTarget = CrowdSurfingVolume.PushTargetLocation - Owner.ActorLocation;
				FVector Direction = ToTarget.SafeNormal;
				Direction = CrowdSurfingVolume.ActorUpVector;
				float Strength = Math::Min(CrowdSurfingVolume.Force, ToTarget.Size());
				Strength = CrowdSurfingVolume.Force;
//				Force += CrowdSurfingVolume.ActorUpVector * CrowdPushForce;
				Force += Direction * Strength;
				ActiveCrowdVolumes++;
			}
		}

		return Force;
	}
};