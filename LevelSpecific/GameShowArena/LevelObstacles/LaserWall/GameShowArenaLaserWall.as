UCLASS(Abstract)
class AGameShowArenaLaserWall : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent LaserMesh;
	default LaserMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	// UPROPERTY(DefaultComponent, Attach = MeshRoot)
	// UStaticMeshComponent LaserMesh02;
	// default LaserMesh02.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision03;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent DeathCollision04;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bStartDisabled = true;

	UPROPERTY(EditInstanceOnly)
	EBombTossChallenges BombTossChallenge;

	UPROPERTY(EditInstanceOnly)
	AGameShowArenaBombHolder ConnectedBombHolder;

	UPROPERTY(EditAnywhere)
	float LowerInterpSpeed = 1000;

	UPROPERTY(EditAnywhere)
	float RaiseInterpSpeed = 2000;

	UPROPERTY(EditAnywhere)
	float LoweredOffset = 600;

	FVector RaisedLocation;
	FVector LoweredLocation;

	bool bIsLowering;

	default ActorTickEnabled = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGameShowArenaLaserWallVisualizerComponent VisualizerComp;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RaisedLocation = ActorLocation;
		LoweredLocation = RaisedLocation - FVector::UpVector * LoweredOffset;
		ConnectedBombHolder.OnBombPickedUp.AddUFunction(this, n"OnBombPickedUp");
		ConnectedBombHolder.ConnectedBomb.OnBombExploded.AddUFunction(this, n"OnBombExploded");
	}

	UFUNCTION()
	private void OnBombExploded(AGameShowArenaBomb Bomb)
	{
		TurnOnLasers();
	}

	UFUNCTION()
	private void OnBombPickedUp()
	{
		TurnOffLasers();
	}

	void TurnOnLasers()
	{
		LaserMesh.RemoveComponentVisualsBlocker(this);
		DeathCollision01.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		DeathCollision02.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		DeathCollision03.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		DeathCollision04.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		UGameShowArenaLaserWallEffectHandler::Trigger_OnLasersEnabled(this);
	}

	void TurnOffLasers()
	{
		LaserMesh.AddComponentVisualsBlocker(this);
		DeathCollision01.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DeathCollision02.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DeathCollision03.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		DeathCollision04.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		UGameShowArenaLaserWallEffectHandler::Trigger_OnLasersDisabled(this);
	}

	UFUNCTION()
	private void OnDeathCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
								 UPrimitiveComponent OtherComp, int OtherBodyIndex,
								 bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
		{
			AGameShowArenaBomb Bomb = Cast<AGameShowArenaBomb>(OtherActor);
			if (Bomb == nullptr)
				return;

			Bomb.CrumbExplode(Bomb.ActorLocation);
			return;
		}

		if (Player.HasControl())
			Player.KillPlayer();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetDeathCollisionEnabled();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		TurnOffLasers();
	}

	UFUNCTION()
	void SetDeathCollisionEnabled()
	{
		TurnOnLasers();
	}

	UFUNCTION()
	void Raise()
	{
		bIsLowering = false;
		ActorTickEnabled = true;
	}

	void Lower()
	{
		bIsLowering = true;
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector TargetLocation;
		float InterpSpeed;
		if (bIsLowering)
		{
			TargetLocation = LoweredLocation;
			InterpSpeed = LowerInterpSpeed;
		}
		else
		{
			TargetLocation = RaisedLocation;
			InterpSpeed = RaiseInterpSpeed;
		}
		FVector NewLocation = Math::VInterpConstantTo(ActorLocation, TargetLocation, DeltaSeconds, InterpSpeed);
		SetActorLocation(NewLocation);

		if (ActorLocation.PointsAreNear(TargetLocation, 50))
			ActorTickEnabled = false;
	}
}

#if EDITOR
class UGameShowArenaLaserWallVisualizerComponent : UActorComponent
{
}

class UGameShowArenaLaserWallVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGameShowArenaLaserWallVisualizerComponent;
	UMaterialInterface DebugMaterial;
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UGameShowArenaLaserWallVisualizerComponent>(Component);
		if (Comp == nullptr)
			return;

		if (DebugMaterial == nullptr)
			DebugMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Game/Editor/Materials/M_Wireframe_Sub.M_Wireframe_Sub"));

		auto LaserWall = Cast<AGameShowArenaLaserWall>(Comp.Owner);
		FVector Wall01RelativeLocation = LaserWall.ActorTransform.InverseTransformPosition(LaserWall.LaserMesh.WorldLocation);
		// FVector Wall02RelativeLocation = LaserWall.ActorTransform.InverseTransformPosition(LaserWall.LaserMesh02.WorldLocation);
		auto LoweredLocation = LaserWall.ActorLocation - FVector::UpVector * LaserWall.LoweredOffset;
		DrawMeshWithMaterial(LaserWall.LaserMesh.StaticMesh, DebugMaterial, LoweredLocation + Wall01RelativeLocation, LaserWall.LaserMesh.ComponentQuat, LaserWall.LaserMesh.WorldScale);
		// DrawMeshWithMaterial(LaserWall.LaserMesh02.StaticMesh, DebugMaterial, LoweredLocation + Wall02RelativeLocation, LaserWall.LaserMesh02.ComponentQuat, LaserWall.LaserMesh02.WorldScale);
		DrawWorldString("Lowered Location", LoweredLocation);

		if (LaserWall.ConnectedBombHolder != nullptr)
			DrawArrow(LaserWall.ConnectedBombHolder.ActorLocation, LaserWall.ActorLocation + FVector::UpVector * 100, FLinearColor::LucBlue, 25, 5, true);
	}
}

#endif