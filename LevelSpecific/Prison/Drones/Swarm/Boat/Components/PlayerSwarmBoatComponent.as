struct FSwarmBoatCameraShakes
{
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> IdleCameraShakeClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> EnterWaterCameraShakeClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LandingCameraShakeClass;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> MagnetDroneBoardingCameraShakeClass;
}

class UPlayerSwarmBoatComponent : UActorComponent
{
	UPROPERTY(Category = "Camera")
	FSwarmBoatCameraSettings CameraSettings;

	UPROPERTY(Category = "Camera", DisplayName = "Shakes")
	FSwarmBoatCameraShakes CameraShakes;

	UPROPERTY(Category = "Boarding")
	FSwarmBoatBoardingParams BoardingParams;

	USwarmBoatSettings Settings;

	UPlayerSwarmDroneComponent SwarmDroneComponent;

	FHazeAcceleratedVector AcceleratedInput;

	FSwarmBoatBoardingEvent OnMagnetDroneBoarded;
	FSwarmBoatBoardingEvent OnMagnetDroneDisembarked;

	access BoatCapability = private, USwarmBoatCapability;
	access : BoatCapability bool bBoatActive;

	access BoatRapids = private, USwarmBoatRapidsEnterCapability, USwarmBoatRapidsMovementCapability;
	access : BoatRapids bool bEnteringRapids, bInRapids;

	private UHazeSplineComponent RapidsSplineComponent = nullptr;

	private FSwarmBoatBeachingParams BeachingParams;

	FQuat BoardingMeshRumble;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		Settings = USwarmBoatSettings::GetSettings(SwarmDroneComponent.Player);
	}

	// 1 propeller
	// 1 tip (giggity)
	// 30 body boats
	UPROPERTY(NotEditable, BlueprintReadOnly)
	const int BotCount = 32; // Touch this and I WILL END YOU!

	void InitializeBoat(float LerpTime)
	{
		// Turn off swarm
		for (int i = 0; i < BotCount; i++)
			SwarmDroneComponent.SwarmBots[i].SetSwarmActive(false);

		// Orient mesh with player (it's fucked due to ball rotation)
		SwarmDroneComponent.DroneMesh.SetWorldRotation(Owner.ActorRotation);

		// Lerp to boat shape
		CreateBoatFormation(LerpTime, 1.4);

		// Add relative offset to mesh to align with proper yaw axis
		SwarmDroneComponent.DroneMesh.SetRelativeLocation(-FVector::ForwardVector * 30.0);
	}

	void DismissBoat()
	{
		// Clear offset
		SwarmDroneComponent.DroneMesh.SetRelativeLocation(FVector::ZeroVector);
	}

	private void CreateBoatFormation(float LerpTime, float Exp)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);

		const float RowSize = 5;

		// Just supports 1, named var for clarity's sake
		const int EngineBotCount = 1;


		// Set relative locations for bots
		float Row = -1;
		for (int i = 0; i < BotCount; i++)
		{
			// Swap attachment and use relative transforms
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			SwarmBot.AttachToComponent(SwarmDroneComponent.DroneMesh);
			SwarmBot.RootComponent.bAbsoluteLocation = false;
			SwarmBot.RootComponent.bAbsoluteRotation = false;

			// Setup engine bots
			if (i == BotCount - EngineBotCount)
			{
				// You are the chosen one
				SwarmBot.bBoatPropeller = true;

				// Locate it behind main raft
				FVector Location = Player.ActorLocation - Player.ActorForwardVector * 40.0;
				FVector RelativeLocation = SwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformPositionNoScale(Location);

				// Rotate to resemble engine
				float DirectionMultiplier = (i % 2 == 0 ? -1 : 1);
				FVector BotToPlayer = (Player.ActorLocation - Location).GetSafeNormal();
				FQuat Rotation = FQuat::MakeFromYZ(Player.MovementWorldUp * DirectionMultiplier, -BotToPlayer);
				FQuat RelativeRotation = SwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformRotation(Rotation);

				// Set initial lerp
				SwarmBot.RelativeLerpOverTime(RelativeLocation, RelativeRotation, LerpTime, Exp);
			}
			// Now handle raft bo(a)ts
			else
			{
				// Didn't want to add a 3rd layer to the math...
				// Tip guy, move this fella to the front
				if (i == BotCount - EngineBotCount - 1)
				{
					FVector Location = Player.ActorLocation + Player.ActorForwardVector * RowSize * 23.5;
					Location += Player.ActorUpVector * 15;

					FVector RelativeLocation = SwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformPositionNoScale(Location);
					FQuat RelativeRotation = FQuat::MakeFromEuler(FVector(0, 70 , 0));

					SwarmBot.RelativeLerpOverTime(RelativeLocation, RelativeRotation, LerpTime, Exp);
				}

				// Build rest of raft
				else
				{
					float Column = i % RowSize;
					if (Column == 0)
						Row++;

					const float Height = 6.0; // 10
					const float Width = 22.0; // 18
					const float RowOffset = (RowSize - 1.0) * 0.5;

					FVector Location = Player.ActorLocation;
					Location += Player.ActorForwardVector * Row * 25 - Player.ActorForwardVector * 30;
					Location += Player.ActorRightVector * (Column - RowOffset) * Width;
					// Location -= Player.MovementWorldUp * 15;

					// Lift sides to make like a boat
					float EdgeMultiplier = Math::Pow(Math::Abs(Column - RowOffset), 2);
					Location += Player.MovementWorldUp * EdgeMultiplier * Height;

					// Don't squew center column if this is an odd number
					float DirectionMultiplier = 0;
					if (Column != int(RowSize / 2))
						DirectionMultiplier = (i % RowSize == 0 ? -1 : 1);

					// Join extremes to, uhm, MaAke lIke aA b0At
					float ColumnMultiplier = 1 - Math::Pow(Row - 1.2, 2);
					ColumnMultiplier = Math::Pow(Math::Abs(Row - RowOffset), 2);
					Location -= Player.ActorRightVector * ColumnMultiplier * (EdgeMultiplier - 1) * DirectionMultiplier * 1;

					FVector RelativeLocation = SwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformPositionNoScale(Location);

					FQuat Rotation = FQuat(Player.ActorForwardVector, (Column - RowOffset) * 0.8* 0.8);// * FQuat(FVector::UpVector, SwarmBot.Id * 1.618);
					FQuat RelativeRotation = SwarmDroneComponent.DroneMesh.WorldTransform.InverseTransformRotation(Rotation);

					// Lerp to transform
					SwarmBot.RelativeLerpOverTime(RelativeLocation, RelativeRotation, LerpTime, Exp);
				}
			}

			// Don't fuck about with the swarm
			SwarmBot.ApplyRespawnBlock(this);
		}
	}

	void EnterBeach(FSwarmBoatBeachingParams Params)
	{
		BeachingParams = Params;
	}

	FSwarmBoatBeachingParams GetBeachingParams() const
	{
		return BeachingParams;
	}

	bool IsBeaching() const
	{
		return !BeachingParams.ExitImpluse.IsZero();
	}

	void ClearBeaching()
	{
		BeachingParams = FSwarmBoatBeachingParams();
	}

	void EnterRapids(AHazeActor SplineActor)
	{
		RapidsSplineComponent = Spline::GetGameplaySpline(SplineActor, this);
		bEnteringRapids = true;
	}

	void ExitRapids()
	{
		RapidsSplineComponent = nullptr;
		bEnteringRapids = false;
		bInRapids = false;

		Drone::GetSwarmDronePlayer().SetActorHorizontalVelocity(FVector::RightVector * 100);
	}

	UFUNCTION()
	UHazeSplineComponent GetRapidsSpline() const
	{
		return RapidsSplineComponent;
	}

	UFUNCTION(BlueprintPure)
	bool IsBoatActive() const
	{
		return bBoatActive;
	}

	UFUNCTION(BlueprintPure)
	bool IsEnteringRapids() const
	{
		return bEnteringRapids;
	}

	UFUNCTION(BlueprintPure)
	bool IsInRapids() const
	{
		return bInRapids;
	}

	bool CanMagnetDroneAttach() const
	{
		if(!IsBoatActive())
			return false;

		if(IsInRapids())
			return false;

		return true;
	}

	bool IsMagnetDroneAttached() const
	{
		auto MagnetDroneAttachToBoatComponent = UMagnetDroneAttachToBoatComponent::Get(Drone::GetMagnetDronePlayer());
		
		if(MagnetDroneAttachToBoatComponent == nullptr)
			return false;

		return MagnetDroneAttachToBoatComponent.IsAttachedToBoat();
	}

	void DetachMagnetDroneFromBoat()
	{
		if(!Settings.bDetachMagnetDroneOnAnyCollision)
			return;

		auto MagnetDroneAttachToBoatComponent = UMagnetDroneAttachToBoatComponent::Get(Drone::GetMagnetDronePlayer());

		if(MagnetDroneAttachToBoatComponent == nullptr)
			return;

		if(!MagnetDroneAttachToBoatComponent.IsAttachedToBoat())
			return;

		MagnetDroneAttachToBoatComponent.DetachFromBoat();
	}
}