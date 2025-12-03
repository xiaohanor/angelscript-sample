UCLASS(Abstract)
class ARedSpaceCollapsingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent CollisionBox;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh MeshAsset;

	UPROPERTY(EditDefaultsOnly)
	UMaterialInterface CubeMaterial;

	UPROPERTY(EditAnywhere)
	int CubeAmount = 8;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ForceFeedback;

	TArray<UStaticMeshComponent> Cubes;
	TArray<FTransform> OriginalTransforms;

	bool bCollapsing = false;
	bool bCollapsed = false;
	bool bResetting = false;
	UPROPERTY(EditAnywhere)
	float CollapseTimer = 2.2;
	UPROPERTY(EditAnywhere)
	float ResetTimer = 3.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (int X = 0; X < CubeAmount; ++X)
		{
			for (int Y = 0; Y < CubeAmount; ++Y)
			{
				for (int Z = 0; Z < 2; ++Z)
				{
					UStaticMeshComponent CubeComp = UStaticMeshComponent::Create(this);
					CubeComp.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld);
					CubeComp.SetStaticMesh(MeshAsset);
					CubeComp.SetRelativeLocation(FVector(25.0 + 50.0 * X, 25.0 + 50.0 * Y, -25.0 + -50.0 * Z));
					CubeComp.SetRelativeScale3D(FVector(1.0));
					CubeComp.SetMaterial(0, CubeMaterial);
					CubeComp.SetCollisionProfileName(n"IgnorePlayerCharacter");
					CubeComp.LDMaxDrawDistance = 8000.0;
				}
			}
		}

		CollisionBox.SetBoxExtent(FVector(25.0* CubeAmount, 25.0 * CubeAmount, 50.0));
		CollisionBox.SetRelativeLocation(FVector(25.0* CubeAmount, 25.0 * CubeAmount, -50.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(UStaticMeshComponent, Cubes);
		for (UStaticMeshComponent Cube : Cubes)
			OriginalTransforms.Add(Cube.RelativeTransform);

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		if (bCollapsing)
			return;

		if (bResetting)
			return;
		
		URedSpaceCollapsingPlatformEffectEventHandler::Trigger_BeforeCollapse(this);
		bCollapsing = true;
		Timer::SetTimer(this, n"Collapse", CollapseTimer);
	}

	UFUNCTION(NotBlueprintCallable)
	void Collapse()
	{
		bCollapsed = true;

		for (UStaticMeshComponent Cube : Cubes)
		{
			Cube.SetSimulatePhysics(true);
			Cube.AddImpulseAtLocation(FVector(0.0, 0.0, 2000.0), ActorLocation);
		}

		URedSpaceCollapsingPlatformEffectEventHandler::Trigger_StartCollapse(this);
		CollisionBox.SetCollisionProfileName(n"NoCollision");
		Timer::SetTimer(this, n"Reset", ResetTimer);

		ForceFeedback::PlayWorldForceFeedback(ForceFeedback, ActorLocation, true, this, 1000.0, 400.0);
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.PlayWorldCameraShake(CamShake, this, ActorLocation, 1000.0, 400.0);
	}

	UFUNCTION()
	private void Reset()
	{
		for (UStaticMeshComponent Cube : Cubes)
		{
			Cube.SetSimulatePhysics(false);
			Cube.AttachToComponent(PlatformRoot, NAME_None, EAttachmentRule::KeepWorld);
		}

		URedSpaceCollapsingPlatformEffectEventHandler::Trigger_StartReset(this);
		bResetting = true;
		bCollapsed = false;
		bCollapsing = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bResetting)
		{
			bool bFullyReset = true;
			for (int i = 0; i <= Cubes.Num() - 1; i++)
			{
				FVector Loc = Math::VInterpTo(Cubes[i].RelativeLocation, OriginalTransforms[i].Location, DeltaTime, 8.0);
				FRotator Rot = Math::RInterpTo(Cubes[i].RelativeRotation, OriginalTransforms[i].Rotator(), DeltaTime, 8.0);
				Cubes[i].SetRelativeLocationAndRotation(Loc, Rot);

				if (!Loc.Equals(OriginalTransforms[i].Location, 2.0))
					bFullyReset = false;
			}

			if (bFullyReset)
			{
				CollisionBox.SetCollisionProfileName(n"BlockOnlyPlayerCharacter");
				bResetting = false;
				Print("FULYREST");
			}
		}

		else if (bCollapsing && !bCollapsed)
		{
			for (UStaticMeshComponent Cube : Cubes)
			{
				float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 30.0) * 30);
				float Pitch = Math::DegreesToRadians(Math::Cos(Time::GameTimeSeconds * 20.0) * 20.0);
				FQuat Rotation = FQuat(FVector::ForwardVector, Roll) * FQuat(FVector::RightVector, Pitch);
				FRotator Rot = Rotation.Rotator();
				Rot.Yaw = Cube.RelativeRotation.Yaw;
				Cube.SetRelativeRotation(Rot);

				Cube.AddLocalRotation(FRotator(0.0, Math::RandRange(360.0, 720.0) * DeltaTime, 0.0));
			}
		}

		float Roll = Math::DegreesToRadians(Math::Sin(Time::GameTimeSeconds * 20.0) * 50.0);
		float Pitch = Math::DegreesToRadians(Math::Cos(Time::GameTimeSeconds * 20.0) * 50.0);
		PlatformRoot.SetRelativeRotation(FRotator(Pitch, 0.0, Roll));
	}
}

class URedSpaceCollapsingPlatformEffectEventHandler : UHazeEffectEventHandler
{

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void BeforeCollapse() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartCollapse() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void StartReset() {}
}