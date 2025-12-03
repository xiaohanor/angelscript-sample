UCLASS(NotBlueprintable)
class UPirateShipMovementComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	float PreSinkOffset = -200;

	UPROPERTY(EditDefaultsOnly)
	float SinkOffset = -2000;

	uint LastAppliedFrame = 0;
	UPirateWaterHeightComponent WaterHeightComp;

	FVector HorizontalVelocity;
	FVector AngularVelocity;
	FVector HorizontalAngularVelocity;
	FHazeAcceleratedQuat AccWaterRotation;

	bool bSteppedRotation = false;
	float LastTimeSetRotation = 0;
	float SteppedRotationInterval = 1.0 / 15;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterHeightComp = UPirateWaterHeightComponent::Get(Owner);
	}

	bool HasAppliedThisFrame() const
	{
		return LastAppliedFrame == Time::FrameNumber;
	}

	void ApplyMoveDelta(FVector Delta, FQuat Rotation, bool bForceOnWater = true)
	{
		FVector NewLocation = Owner.ActorLocation + Delta;
		ApplyMoveLocation(NewLocation, Rotation, bForceOnWater);
	}

	void ApplyMoveLocation(FVector Location, FQuat Rotation, bool bForceOnWater = true)
	{
		check(!HasAppliedThisFrame());
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		check(HazeOwner != nullptr);

		FVector NewLocation;
		if(bForceOnWater)
			NewLocation = FVector(Location.X, Location.Y, WaterHeightComp.GetWaterHeight());
		else
			NewLocation = Location;

		FVector PreviousLocation = Owner.ActorLocation;
		FQuat PreviousRotation = Owner.ActorQuat;

		FQuat NewRotation = Rotation;
		if(bSteppedRotation)
		{
			if(Time::GetGameTimeSince(LastTimeSetRotation) < SteppedRotationInterval)
			{
				NewRotation = Owner.ActorQuat;
			}
			else
			{
				LastTimeSetRotation = Time::GameTimeSeconds;
			}
		}

		Owner.SetActorLocationAndRotation(NewLocation, NewRotation);

		const float DeltaTime = Time::GetActorDeltaSeconds(HazeOwner);

		FVector Delta = NewLocation - PreviousLocation;
		HazeOwner.SetActorVelocity(Delta / DeltaTime);

		HorizontalVelocity = Owner.ActorVelocity.VectorPlaneProject(FVector::UpVector);

		FQuat DeltaRotation = Rotation * PreviousRotation.Inverse();
		FVector AngularVelocityAxis = FVector::UpVector;
		float AngularVelocityAngle = 0;
		DeltaRotation.ToAxisAndAngle(AngularVelocityAxis, AngularVelocityAngle);
		AngularVelocity = AngularVelocityAxis * (AngularVelocityAngle / DeltaTime);

		FRotator DeltaRotator = DeltaRotation.Rotator();
		HorizontalAngularVelocity = FVector::UpVector * (DeltaRotator.Yaw / DeltaTime);

		LastAppliedFrame = Time::FrameNumber;
	}

	void AddRotationalImpulse(FVector Impulse)
	{
		FVector Right = -FVector::UpVector.CrossProduct(Impulse).GetSafeNormal();

		const float ImpulseAlpha = Math::NormalizeToRange(Impulse.Size(), Pirate::Ship::ImpulseNeededForImpact, Pirate::Ship::ImpulseNeededForMaxImpact);
		const float ImpulseSize = Math::Lerp(Pirate::Ship::ImpactMinImpulse, Pirate::Ship::ImpactMaxImpulse, ImpulseAlpha);

		AccWaterRotation.VelocityAxisAngle += Right * ImpulseSize;
	}

	FVector GetVelocityAtPoint(FVector Point, float AngularMultiplier = 1) const
	{
		FVector COM = Owner.ActorLocation;
		FVector Diff = Point - COM;
		return Owner.ActorVelocity - (Diff.CrossProduct(AngularVelocity) * AngularMultiplier);
	}

	FVector GetVelocityAtPointHorizontalOnly(FVector Point, float AngularMultiplier = 1) const
	{
		FVector COM = Owner.ActorLocation;
		FVector Diff = Point - COM;
		return HorizontalVelocity - (Diff.CrossProduct(HorizontalAngularVelocity) * AngularMultiplier);
	}
};