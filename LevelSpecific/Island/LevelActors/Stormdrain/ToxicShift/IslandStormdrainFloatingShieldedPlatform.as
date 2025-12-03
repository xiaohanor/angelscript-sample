event void FIslandStormdrainFloatingShieldedPlatformEnterExitShieldEvent(AIslandStormdrainFloatingShieldedPlatform Platform, AHazePlayerCharacter Player);

class AIslandStormdrainFloatingShieldedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.Friction = 12.0;
	default ConeRotateComp.ForceScalar = 0.5;
	default ConeRotateComp.SpringStrength = 0.2;
	default ConeRotateComp.ConeAngle = 10.0;
	default ConeRotateComp.ConstrainBounce = 0.0;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsTranslateComponent TranslateComp;
	default TranslateComp.SpringStrength = 1.5;
	default TranslateComp.Friction = 4.0;
	default TranslateComp.bConstrainX = true;
	default TranslateComp.MaxX = 40.0;
	default TranslateComp.MinX = -40.0;
	default TranslateComp.bConstrainY = true;
	default TranslateComp.MaxY = 40.0;
	default TranslateComp.MinY = -40.0;
	default TranslateComp.bConstrainZ = true;
	default TranslateComp.MaxZ = 0.0;
	default TranslateComp.MinZ = -70.0;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 100.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.2;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent PlatformMesh;
	default PlatformMesh.bBlockVisualsOnDisable = false;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UHazeMovablePlayerTriggerComponent PlayerEnterTrigger;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandStormdrainFloatingShieldedPlatformDummyComp DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;
	
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5000.0;

	UPROPERTY(EditAnywhere, Category = "Respawn Point")
	ARespawnPoint RespawnPoint;

	UPROPERTY(EditAnywhere, Category = "Respawn Point")
	int RespawnPointPriority = -1;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UStaticMesh SquarePlatformMesh;

	UPROPERTY(EditAnywhere, Category = "Setup")
	UStaticMesh RoundPlatformMesh;

	UPROPERTY(EditAnywhere, Category = "Shields")
	bool bSphereShield = true;

	UPROPERTY(EditAnywhere, Category = "Shields")
	EIslandRedBlueShieldType StartColor = EIslandRedBlueShieldType::Red; 
	
	UPROPERTY(EditAnywhere, Category = "Shields")
	bool bDisablePlatform = false;

	UPROPERTY(EditAnywhere, Category = "Shields")
	bool bScalePlatformWithShields = true;
	
	UPROPERTY(EditAnywhere, Category = "Shields")
	bool bMendShieldsWhenSwapping = true;

	UPROPERTY(EditAnywhere, Category = "Shields")
	bool bProtectsPlayers = true;

	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "!bSphereShield", EditConditionHides))
	bool bPutShieldAtBottom = true;

	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "bSphereShield", EditConditionHides))
	EIslandRedBlueForceFieldSphereType SphereType;
	default SphereType = EIslandRedBlueForceFieldSphereType::Dome;

	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "bSphereShield", EditConditionHides))
	float SphereRadius = 480.0;
	
	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "!bSphereShield", EditConditionHides))
	FVector ShieldExtents = FVector(600, 600, 600);

	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "!bSphereShield", EditConditionHides))
	TSubclassOf<AIslandRedBlueForceField> SquareShieldClass;

	UPROPERTY(EditAnywhere, Category = "Shields", Meta = (EditCondition = "bSphereShield", EditConditionHides))
	TSubclassOf<AIslandRedBlueForceField> SphereShieldClass;

	UPROPERTY(EditAnywhere, Category = "Faux Physics")
	bool bEnableFauxPhysics = true;

	UPROPERTY(EditAnywhere, Category = "Shields")
	UMaterialInterface RedRingMaterial;

	UPROPERTY(EditAnywhere, Category = "Shields")
	UMaterialInterface BlueRingMaterial;

	TArray<AIslandRedBlueForceField> Shields;
	TPerPlayer<bool> IsInsideShields;

	APlayerTrigger PlayerTrigger;
	bool bIsOverlappingHazardousWave = false;

	FIslandStormdrainFloatingShieldedPlatformEnterExitShieldEvent OnPlayerEnterShields;
	FIslandStormdrainFloatingShieldedPlatformEnterExitShieldEvent OnPlayerExitShields;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors; 
		GetAttachedActors(AttachedActors, true, true);
		for(auto Actor : AttachedActors)
		{
			auto Shield = Cast<AIslandRedBlueForceField>(Actor);
			if(Shield != nullptr)
			{
				Shields.Add(Shield);

				if(Shields.Num() == 1)
					Shields[0].OnChangeForceFieldType.AddUFunction(this, n"OnChangeForceFieldType");

				Shield.AttachToComponent(TranslateComp, n"Name_NONE", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
				Shield.SetForceFieldType(StartColor);
			}
		}

		if(bSphereShield)
		{
			for(auto Player : Game::Players)
			{
				UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnRespawn");
			}
		}

		if(bDisablePlatform)
		{
			PlatformMesh.CollisionEnabled = ECollisionEnabled::QueryOnly;
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Ignore);
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Ignore);
		}
		else
		{
			PlatformMesh.CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Block);
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Camera, ECollisionResponse::ECR_Block);
			PlatformMesh.SetCollisionResponseToChannel(ECollisionChannel::ECC_Visibility, ECollisionResponse::ECR_Block);
		}

		if(bEnableFauxPhysics)
		{
			ConeRotateComp.bStartDisabled = false;
			TranslateComp.bStartDisabled = false;
		}
		else
		{
			ConeRotateComp.bStartDisabled = true;
			TranslateComp.bStartDisabled = true;
		}

		if(bSphereShield)
		{
			PlayerEnterTrigger.DisableTrigger(this);
			SetActorTickEnabled(true);
		}
		else
		{
			PlayerEnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnteredTrigger");
			PlayerEnterTrigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeftTrigger");
			FVector BoxCollisionExtents = ShieldExtents * 0.5
				- FVector::RightVector * 32 // Player collision capsule radius
				- FVector::ForwardVector * 32 // Player collision capsule radius
				- FVector::UpVector * 82; // Player collision capsule half height
			PlayerEnterTrigger.ChangeShape(FHazeShapeSettings::MakeBox(BoxCollisionExtents));
			PlayerEnterTrigger.RelativeLocation = FVector(0, 0, ShieldExtents.Z * 0.5);
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void OnRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		UpdatePlayerInSphere(RespawnedPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSphereShield)
			return;

		for(auto Player : Game::Players)
		{
			UpdatePlayerInSphere(Player);
		}
	}

	private void UpdatePlayerInSphere(AHazePlayerCharacter Player)
	{
		float DistToPlayerSquared = Player.ActorCenterLocation.DistSquared(ActorLocation);

		bool bPlayerIsSafe = DistToPlayerSquared <= Math::Square(SphereRadius);
		// Have to check if underneath the platform if it's a dome because distance assumes sphere 
		if(SphereType == EIslandRedBlueForceFieldSphereType::Dome
		&& Player.ActorCenterLocation.Z < TranslateComp.WorldLocation.Z)
			bPlayerIsSafe = false;

		if(bPlayerIsSafe)
			SetPlayerIsInsideShields(Player, true);
		else
			SetPlayerIsInsideShields(Player, false);
	}

	UFUNCTION()
	private void OnChangeForceFieldType(EIslandRedBlueShieldType NewType)
	{
		if(!bSphereShield)
			return;

		if(NewType == EIslandRedBlueShieldType::Red)
			PlatformMesh.SetMaterial(2, RedRingMaterial);
		else if(NewType == EIslandRedBlueShieldType::Blue)
			PlatformMesh.SetMaterial(2, BlueRingMaterial);
	}

	UFUNCTION()
	private void OnPlayerEnteredTrigger(AHazePlayerCharacter Player)
	{
		SetPlayerIsInsideShields(Player, true);
	}

	UFUNCTION()
	private void OnPlayerLeftTrigger(AHazePlayerCharacter Player)
	{
		SetPlayerIsInsideShields(Player, false);
	}

	void SetPlayerIsInsideShields(AHazePlayerCharacter Player, bool bIsInside)
	{
		if(!bProtectsPlayers)
			return;

		if(bIsInside != IsInsideShields[Player])
		{
			if(bIsInside)
				OnPlayerEnterShields.Broadcast(this, Player);
			else
				OnPlayerExitShields.Broadcast(this, Player);
		}

		IsInsideShields[Player] = bIsInside;
	}

	void ToggleShieldColors()
	{
		for(auto Shield : Shields)
		{
			EIslandRedBlueShieldType NewType;
			if(Shield.ForceFieldType == EIslandRedBlueShieldType::Red)
				NewType = EIslandRedBlueShieldType::Blue;
			else
				NewType = EIslandRedBlueShieldType::Red;
			Shield.SetForceFieldType(NewType);
		}
	}

	void MendShields()
	{
		for(auto Shield : Shields)
		{
			Shield.MendAllHoles();
		}
	}

	UFUNCTION(CallInEditor, Category = "Shields")
	void PlaceShields()
	{
		TArray<AActor> AttachedActors; 
		GetAttachedActors(AttachedActors, true, true);
		if(!AttachedActors.IsEmpty())
		{
			for(int i = AttachedActors.Num() - 1; i >= 0; i--)
			{
				auto Actor = AttachedActors[i];
				if(Actor.IsA(AIslandRedBlueForceField))
				{
					AttachedActors.RemoveAt(i);
					if(Actor != nullptr)
						Actor.DestroyActor();
				}
			}
		}

		TArray<FTransform> ShieldTransforms;
		if(bSphereShield)
		{
			float ScaleAlpha = Math::GetPercentageBetween(0, 480, SphereRadius);
			ShieldTransforms.Add(FTransform(ActorRotation, ActorLocation, FVector(ScaleAlpha, ScaleAlpha, ScaleAlpha)));
		}
		else
		{
			FVector ShieldLocation;
			FQuat ShieldRotation;
			FVector ShieldScale;

			// BACK
			ShieldLocation = ActorLocation
				- (ActorForwardVector * ShieldExtents.X * 0.5)
				+ (ActorUpVector * ShieldExtents.Z * 0.5);
			ShieldRotation = FQuat::MakeFromXY(-ActorForwardVector, ActorRightVector);
			ShieldScale = FVector(ShieldExtents.Z * 0.01, ShieldExtents.Y * 0.01, 1.0);
			FTransform BackShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
			ShieldTransforms.Add(BackShieldTransform);

			// FRONT
			ShieldLocation = ActorLocation
				+ (ActorForwardVector * ShieldExtents.X * 0.5)
				+ (ActorUpVector * ShieldExtents.Z * 0.5);
			ShieldRotation = FQuat::MakeFromXY(ActorForwardVector, ActorRightVector);
			ShieldScale = FVector(ShieldExtents.Z * 0.01, ShieldExtents.Y * 0.01, 1.0);
			FTransform FrontShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
			ShieldTransforms.Add(FrontShieldTransform);

			// LEFT
			ShieldLocation = ActorLocation
				- (ActorRightVector * ShieldExtents.Y * 0.5)
				+ (ActorUpVector * ShieldExtents.Z * 0.5);
			ShieldRotation = FQuat::MakeFromXY(-ActorRightVector, ActorForwardVector);
			ShieldScale = FVector(ShieldExtents.Z * 0.01, ShieldExtents.X * 0.01, 1.0);
			FTransform LeftShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
			ShieldTransforms.Add(LeftShieldTransform);

			// RIGHT
			ShieldLocation = ActorLocation
				+ (ActorRightVector * ShieldExtents.Y * 0.5)
				+ (ActorUpVector * ShieldExtents.Z * 0.5);
			ShieldRotation = FQuat::MakeFromXY(ActorRightVector, ActorForwardVector);
			ShieldScale = FVector(ShieldExtents.Z * 0.01, ShieldExtents.X * 0.01, 1.0);
			FTransform RightShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
			ShieldTransforms.Add(RightShieldTransform);

			// UP
			ShieldLocation = ActorLocation
				+ (ActorUpVector * ShieldExtents.Z);
			ShieldRotation = FQuat::MakeFromXY(ActorUpVector, ActorRightVector);
			ShieldScale = FVector(ShieldExtents.X * 0.01, ShieldExtents.Y * 0.01, 1.0);
			FTransform UpShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
			ShieldTransforms.Add(UpShieldTransform);

			if(bPutShieldAtBottom)
			{
				// DOWN
				ShieldLocation = ActorLocation;
				ShieldRotation = FQuat::MakeFromXY(-ActorUpVector, ActorRightVector);
				ShieldScale = FVector(ShieldExtents.X * 0.01, ShieldExtents.Y * 0.01, 1.0);
				FTransform DownShieldTransform = FTransform(ShieldRotation, ShieldLocation, ShieldScale);
				ShieldTransforms.Add(DownShieldTransform);
			}

		}

		for(auto Transform : ShieldTransforms)
		{
			auto ShieldClass = bSphereShield ? SphereShieldClass : SquareShieldClass;

			auto Shield = SpawnActor(ShieldClass, Transform.Location, Transform.Rotator());
			Shield.AttachToComponent(TranslateComp, n"Name_NONE", EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, true);
			Shield.SetForceFieldType(StartColor);
			Shield.WallMesh_FrontPlane.RelativeLocation = FVector::ZeroVector;
			Shield.StickyGrenadeResponseComp.RelativeLocation = FVector::ZeroVector;
			Shield.WallMesh_FrontPlane.WorldScale3D = Transform.Scale3D;
			if(Shield.bAutomaticallySetShapeBasedOnForceFieldBounds)
			{
				FBox Box = Shield.CollisionMesh.GetBoundingBoxRelativeToOwner();
				if(bSphereShield)
				{
					Shield.StickyGrenadeResponseComp.Shape = FHazeShapeSettings::MakeSphere(Box.Extent.X);
				}
				else
				{
					Shield.StickyGrenadeResponseComp.Shape = FHazeShapeSettings::MakeBox(Box.Extent);
					Shield.StickyGrenadeResponseComp.WorldLocation = ActorTransform.TransformPosition(Box.Center);
				}
			}
			Shield.SphereType = SphereType;
			Shield.UpdateSphereMesh();
		}

		if(bDisablePlatform)
			PlatformMesh.SetVisibility(false);
		else
			PlatformMesh.SetVisibility(true);
	}
	
	int opCmp(AIslandStormdrainFloatingShieldedPlatform Other) const
	{
		if (RespawnPointPriority < Other.RespawnPointPriority)
			return -1;
		else if (RespawnPointPriority > Other.RespawnPointPriority)
			return 1;
		else
			return 0;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(bSphereShield)
		{
			if(bScalePlatformWithShields)
			{
				PlatformMesh.StaticMesh = RoundPlatformMesh;
				float ScaleAlpha = Math::GetPercentageBetween(0, 480, SphereRadius);
				PlatformMesh.SetWorldScale3D(FVector(ScaleAlpha));
			}
			else
			{
				PlatformMesh.SetWorldScale3D(FVector::OneVector);
			}
		}
		else
		{
			if(bScalePlatformWithShields)
				PlatformMesh.WorldScale3D = FVector(ShieldExtents.X * 0.00175, ShieldExtents.Y * 0.00175, 1.0);
			else
				PlatformMesh.WorldScale3D = FVector(1.0, 1.0, 1.0);
			PlatformMesh.StaticMesh = SquarePlatformMesh;
		}

		if(bDisablePlatform)
			PlatformMesh.SetVisibility(false);
		else
			PlatformMesh.SetVisibility(true);

		FVector BoxCollisionExtents = ShieldExtents * 0.5
			- FVector::RightVector * 32 // Player collision capsule radius
			- FVector::ForwardVector * 32 // Player collision capsule radius
			- FVector::UpVector * 82; // Player collision capsule half height
		PlayerEnterTrigger.ChangeShape(FHazeShapeSettings::MakeBox(BoxCollisionExtents));
		PlayerEnterTrigger.RelativeLocation = FVector(0, 0, ShieldExtents.Z * 0.5);
	}
#endif
};

#if EDITOR
class UIslandStormdrainFloatingShieldedPlatformDummyComp : UActorComponent {};
class UIslandStormdrainFloatingShieldedPlatformComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandStormdrainFloatingShieldedPlatformDummyComp;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto VisualizeComponent = Cast<UIslandStormdrainFloatingShieldedPlatformDummyComp>(Component);
		if(VisualizeComponent == nullptr)
			return;

		auto Platform = Cast<AIslandStormdrainFloatingShieldedPlatform>(VisualizeComponent.Owner);
		if(Platform == nullptr)
			return;

		SetRenderForeground(true);

		FLinearColor ShieldColor;
		if(Platform.StartColor == EIslandRedBlueShieldType::Red)
			ShieldColor = FLinearColor::Red;
		else
			ShieldColor = FLinearColor::Blue;

		if(Platform.bSphereShield)
		{
			DrawWireSphere(Platform.ActorLocation, Platform.SphereRadius, ShieldColor, 10, 12, false);
		}
		else
		{
			FVector BackShieldLocation = Platform.ActorLocation
				- (Platform.ActorForwardVector * Platform.ShieldExtents.X * 0.5)
				+ (Platform.ActorUpVector * Platform.ShieldExtents.Z * 0.5);

			FQuat BackShieldRotation = FQuat::MakeFromXY(Platform.ActorForwardVector, Platform.ActorRightVector);

			FVector FrontShieldLocation = Platform.ActorLocation
				+ (Platform.ActorForwardVector * Platform.ShieldExtents.X * 0.5)
				+ (Platform.ActorUpVector * Platform.ShieldExtents.Z * 0.5);

			FQuat FrontShieldRotation = FQuat::MakeFromXY(-Platform.ActorForwardVector, Platform.ActorRightVector);

			FVector LeftShieldLocation = Platform.ActorLocation
				- (Platform.ActorRightVector * Platform.ShieldExtents.Y * 0.5)
				+ (Platform.ActorUpVector * Platform.ShieldExtents.Z * 0.5);

			FQuat LeftShieldRotation = FQuat::MakeFromXY(-Platform.ActorRightVector, Platform.ActorForwardVector);

			FVector RightShieldLocation = Platform.ActorLocation
				+ (Platform.ActorRightVector * Platform.ShieldExtents.Y * 0.5)
				+ (Platform.ActorUpVector * Platform.ShieldExtents.Z * 0.5);

			FQuat RightShieldRotation = FQuat::MakeFromXY(Platform.ActorRightVector, Platform.ActorForwardVector);

			FVector UpShieldLocation = Platform.ActorLocation
				+ (Platform.ActorUpVector * Platform.ShieldExtents.Z);

			FQuat UpShieldRotation = FQuat::MakeFromXY(Platform.ActorUpVector, Platform.ActorRightVector);

			FVector ShieldBoxExtents;
			ShieldBoxExtents = FVector(1.0, Platform.ShieldExtents.Y * 0.5, Platform.ShieldExtents.Z * 0.5);
			DrawWireBox(BackShieldLocation, ShieldBoxExtents, BackShieldRotation, ShieldColor, 10);
			DrawWireBox(FrontShieldLocation, ShieldBoxExtents, FrontShieldRotation, ShieldColor, 10);
			ShieldBoxExtents = FVector(1.0, Platform.ShieldExtents.X * 0.5, Platform.ShieldExtents.Z * 0.5);
			DrawWireBox(LeftShieldLocation, ShieldBoxExtents, LeftShieldRotation, ShieldColor, 10);
			DrawWireBox(RightShieldLocation, ShieldBoxExtents, RightShieldRotation, ShieldColor, 10);
			ShieldBoxExtents = FVector(1.0, Platform.ShieldExtents.Y * 0.5, Platform.ShieldExtents.X * 0.5);
			DrawWireBox(UpShieldLocation, ShieldBoxExtents, UpShieldRotation, ShieldColor, 10);
		}
	}
}
#endif
