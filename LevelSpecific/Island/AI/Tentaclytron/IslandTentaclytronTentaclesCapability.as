class UIslandTentaclytronTentacleSettings : UHazeComposableSettings
{
	// Number of tentacles. Block and unblock companion tentacle capability to update this.
	UPROPERTY(Category = "Tentacles")
	int NumTentacles = 6;

	// Distance from actor origin to tentacle origin
	UPROPERTY(Category = "Tentacles")
	float TentacleOriginRadius = 3.0;

	// Resting length of tentacle
	UPROPERTY(Category = "Tentacles")
	float TentacleLength = 600.0;

	UPROPERTY(Category = "Tentacles")
	float NearFraction = 0.3;
	UPROPERTY(Category = "Tentacles")
	float NearStiffness = 200.0;
	UPROPERTY(Category = "Tentacles")
	float NearDamping = 0.9;

	UPROPERTY(Category = "Tentacles")
	float FarFraction = 0.6;
	UPROPERTY(Category = "Tentacles")
	float FarStiffness = 6.0;
	UPROPERTY(Category = "Tentacles")
	float FarDamping = 0.3;

	UPROPERTY(Category = "Tentacles")
	float EndStiffness = 4.0;
	UPROPERTY(Category = "Tentacles")
	float EndDamping = 0.2;
};

struct FIslandTentaclytronTentacle
{
	UNiagaraComponent Effect;
	FVector LocalOrigin;
	FHazeAcceleratedVector AccNear;
	FHazeAcceleratedVector AccFar;
	FHazeAcceleratedVector AccEnd;
}

class UIslandTentaclytronTentaclesCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(n"Tentacles");
	default TickGroup = EHazeTickGroup::AfterGameplay;

	UIslandTentaclytronTentaclesComponent TentaclesComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandTentaclytronTentacleSettings Settings;

	TArray<FIslandTentaclytronTentacle> Tentacles;
	int iTentacle;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TentaclesComp = UIslandTentaclytronTentaclesComponent::GetOrCreate(Owner); 	
		MoveComp = UBasicAICharacterMovementComponent::GetOrCreate(Owner);	
		Settings = UIslandTentaclytronTentacleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Settings.NumTentacles == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Settings.NumTentacles == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FTransform Transform = Owner.ActorTransform;
		float Interval = 2.0 * PI / float(Settings.NumTentacles);
		for (int i = 0; i < Settings.NumTentacles; i++)
		{
			FIslandTentaclytronTentacle Tentacle;
			Tentacle.Effect = Niagara::SpawnLoopingNiagaraSystemAttached(TentaclesComp.TentacleFX, Owner.RootComponent);
			FVector Dir = FVector(0.0, Math::Cos(i * Interval), Math::Sin(i * Interval));
			Tentacle.LocalOrigin = Dir * Settings.TentacleOriginRadius * Math::RandRange(0.7, 1.3);
			FVector WorldOrigin = Transform.TransformPosition(Tentacle.LocalOrigin);
			Tentacle.AccNear.SnapTo(WorldOrigin);
			Tentacle.AccFar.SnapTo(WorldOrigin);
			Tentacle.AccEnd.SnapTo(WorldOrigin);
			Tentacles.Add(Tentacle);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (FIslandTentaclytronTentacle Tentacle : Tentacles)
		{
			Tentacle.Effect.Deactivate();
		}
		Tentacles.Empty();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform Transform = Owner.ActorTransform;
		FVector SocketLoc = Cast<AHazeCharacter>(Owner).Mesh.GetSocketLocation(n"Spine1");
		Transform.Location = SocketLoc;

		for (FIslandTentaclytronTentacle& Tentacle : Tentacles)
		{
			FVector Origin = Transform.TransformPosition(Tentacle.LocalOrigin);
			FVector End = Origin - Owner.ActorForwardVector * Settings.TentacleLength;
			FVector Delta = (End - Origin);
			FVector Dir = (Origin - SocketLoc).ConstrainToPlane(Owner.ActorForwardVector).GetSafeNormal();
			Tentacle.AccNear.SpringTo(Origin + Dir * 5.0 + Delta * Settings.NearFraction, Settings.NearStiffness, Settings.NearDamping, DeltaTime);
			Tentacle.AccFar.SpringTo(Origin + Delta * Settings.FarFraction, Settings.FarStiffness, Settings.FarDamping, DeltaTime);
			Tentacle.AccEnd.SpringTo(End + Dir * 10.0, Settings.EndStiffness, Settings.EndDamping, DeltaTime);

			Tentacle.Effect.SetVectorParameter(n"P0", Origin); 
			Tentacle.Effect.SetVectorParameter(n"P1", Tentacle.AccNear.Value); 
			Tentacle.Effect.SetVectorParameter(n"P2", Tentacle.AccFar.Value); 
			Tentacle.Effect.SetVectorParameter(n"P3", Tentacle.AccEnd.Value); 
		}
	}
}
