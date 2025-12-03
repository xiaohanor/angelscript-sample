struct FFlyingCritter
{
	UStaticMeshComponent MeshComp;

	FVector Velocity;

	float RotateSpeed;

	FVector Position;

	FVector LastPosition;

	FVector Destination;
	FVector TargetVelocity;

	float MoveTimer;

	bool bMoving;
}

enum EFlyingCritterMovementStyle
{
	Random,
	Dragonfly,
	Circling,
};

class ACritterFlying : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.0;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	USphereComponent DebugSphere;
	default DebugSphere.CollisionProfileName = n"NoCollision";
#endif
	
	UPROPERTY(EditAnywhere, Category="Default")
	UStaticMesh Mesh;

	UPROPERTY(EditAnywhere, Category="Default")
	TArray<UMaterialInterface> RandomMaterials;
	
	UPROPERTY(EditAnywhere, Category="Default")
	int RandomMaterialTargetIndex = 0;
	
	UPROPERTY(EditAnywhere, Category="Default")
	bool bRestrictToPlane = false;

	UPROPERTY(EditAnywhere, Category="Default")
	float FlyRadius = 2500;
	
	UPROPERTY(EditAnywhere, Category="Default")
	int CritterCount = 4.0f;

	UPROPERTY(EditAnywhere, Category="Default")
	float Scale = 1;
	
	UPROPERTY(EditAnywhere, Category="Default")
	EFlyingCritterMovementStyle MovementStyle = EFlyingCritterMovementStyle::Circling;
	
	UPROPERTY(EditAnywhere, Category="Default|Dragonfly", Meta = (EditCondition = "MovementStyle == EFlyingCritterMovementStyle::Dragonfly", EditConditionHides))
	bool bDragonflyJudder = true;

	UPROPERTY(EditAnywhere, Category="Default|Random", Meta = (EditCondition = "MovementStyle == EFlyingCritterMovementStyle::Random", EditConditionHides))
	float RandomFlySpeed = 200.0;

	UPROPERTY(EditAnywhere, Category="Default|Circling", Meta = (EditCondition = "MovementStyle == EFlyingCritterMovementStyle::Circling", EditConditionHides))
	float CirclingFlySpeed = 800.0;

	UPROPERTY(EditAnywhere, Category="Default|Circling", Meta = (EditCondition = "MovementStyle == EFlyingCritterMovementStyle::Circling", EditConditionHides))
	bool bCirclingForceIntoRadius = false;

	TArray<FFlyingCritter> Critters;
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		DebugSphere.SphereRadius = FlyRadius;

		for (int i = 0; i < CritterCount; i++)
		{
			FVector StartPos = GetActorLocation() + Math::GetRandomPointOnSphere() * Math::RandRange(0.0, 1.0) * FlyRadius;

			auto NewMesh = CreateComponent(UStaticMeshComponent);
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			NewMesh.bIsEditorOnly = true;
			NewMesh.WorldLocation = StartPos;
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Mesh == nullptr)
			return;
			
		Critters = TArray<FFlyingCritter>();
		for (int i = 0; i < CritterCount; i++)
		{
			FVector StartPos = GetActorLocation() + Math::GetRandomPointOnSphere() * Math::RandRange(0.0, 1.0) * FlyRadius;

			auto NewMesh = CreateComponent(UStaticMeshComponent);
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";

			FFlyingCritter Critter;
			Critter.MeshComp = NewMesh;
			Critter.MeshComp.SetWorldLocation(StartPos);
			Critter.Position = StartPos;
			Critter.MeshComp.SetWorldRotation(FRotator(0, Math::RandRange(0, 360), 0));
			Critter.MoveTimer = 0.0;
			Critter.MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
			if(MovementStyle == EFlyingCritterMovementStyle::Circling)
			{
				float RotationSpeed = Math::RandRange(20.0, 50.0) / 800.0;
				if(bCirclingForceIntoRadius)
				{
					RotationSpeed = 360 / (FlyRadius*2.0);
				}

				Critter.RotateSpeed = RotationSpeed;
				Critter.RotateSpeed *= Math::RandBool() ? -1 : 1;
			}
			if(RandomMaterials.Num() > 0)
			{
				int index = Math::RandRange(0, RandomMaterials.Num() - 1);
				auto RandomMaterial = RandomMaterials[index];
				Critter.MeshComp.SetMaterial(RandomMaterialTargetIndex, RandomMaterial);
			}

			Critters.Add(Critter);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector ActorPos = GetActorLocation();

		for (int i = 0; i < CritterCount; i++)
		{
			FFlyingCritter& Critter = Critters[i];

			if(MovementStyle == EFlyingCritterMovementStyle::Random)
			{
				Critter.MoveTimer -= DeltaTime;
				if (Critter.MoveTimer <= 0.0)
				{
					Critter.MoveTimer = Math::RandRange(1.0, 2.0);
					Critter.Destination = Critter.Position + Math::GetRandomPointOnSphere() * 100.0;
					Critter.TargetVelocity = Critter.Destination - Critter.LastPosition;
					Critter.TargetVelocity.Normalize();
				}

				Critter.Velocity = Math::VInterpConstantTo(Critter.Velocity, Critter.TargetVelocity, DeltaTime, 1.0);

				FRotator Rotation = Critter.MeshComp.WorldRotation;
				if (!Critter.Velocity.IsNearlyZero())
				Rotation.Yaw = FRotator::MakeFromX(Critter.Velocity).Yaw;

				FVector WorldLocation = Critter.MeshComp.WorldLocation;
				WorldLocation += Critter.Velocity * 50.0 * DeltaTime;

				Critter.MeshComp.SetWorldLocationAndRotation(WorldLocation, Rotation);
			}
			else if(MovementStyle == EFlyingCritterMovementStyle::Circling)
			{
				FRotator Rotation = Critter.MeshComp.WorldRotation;
				Rotation.Yaw += Critter.RotateSpeed * CirclingFlySpeed * DeltaTime;

				FVector WorldLocation = Critter.MeshComp.WorldLocation;
				WorldLocation += Rotation.ForwardVector * CirclingFlySpeed * DeltaTime;

				Critter.MeshComp.SetWorldLocationAndRotation(WorldLocation, Rotation);
			}
			else /*if(MovementStyle == EFlyingCritterMovementStyle::Dragonfly)*/
			{
				FVector WorldLocation = Critter.MeshComp.WorldLocation;

				if(Critter.bMoving)
				{
					if(WorldLocation.Distance(ActorPos) > FlyRadius)
					{
						Critter.Velocity = ActorPos - WorldLocation; // Vector from current pos to sphere center.
					}
					Critter.Velocity.Normalize();
					WorldLocation += (Critter.Velocity * DeltaTime * 2000);
				}
				else
				{
					Critter.Velocity += Math::GetRandomPointOnSphere();
				
					// If critter is outside sphere, move it back.
					if(WorldLocation.Distance(ActorPos) > FlyRadius)
						Critter.Velocity = ActorPos - WorldLocation; // Vector from current pos to sphere center.

					Critter.Velocity.Normalize();

					if(bDragonflyJudder)
						WorldLocation += (Critter.Velocity * DeltaTime * 100);
				}
				
				Critter.MoveTimer -= DeltaTime;

				if(Critter.MoveTimer <= 0)
				{
					Critter.bMoving = !Critter.bMoving;
					if(Critter.bMoving)
					{
						Critter.MoveTimer = Math::RandRange(0.1, 0.2);
					}
					else
					{
						Critter.MoveTimer = Math::RandRange(0.2, 8.0);
					}
				}

				if(bRestrictToPlane)
					WorldLocation.Z = ActorLocation.Z;

				Critter.MeshComp.SetWorldLocation(WorldLocation);
			}

			FVector CurrentPosition = Critter.MeshComp.WorldLocation;
			float CritterVelocity = (Critter.LastPosition - CurrentPosition).Size() / DeltaTime;
			Critter.LastPosition = CurrentPosition;
		}
	}
}
