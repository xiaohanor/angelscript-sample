UCLASS(Abstract)
class APrisonPerchSpiral : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpiralRoot;

	UPROPERTY(DefaultComponent, Attach = SpiralRoot)
	USceneComponent TopSpiralRoot;

	UPROPERTY(DefaultComponent, Attach = SpiralRoot)
	USceneComponent MiddleSpiralRoot;

	UPROPERTY(DefaultComponent, Attach = SpiralRoot)
	USceneComponent BottomSpiralRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6500;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<APrisonPerchSpiralArm> ArmClass;

	float RotationSpeed = 4.5;

	float TopOffset = 4000.0;
	float MiddleOffset = 2000.0;
	float BottomOffset = 0.0;
	float SinkSpeed = 15.0;

	UPROPERTY(EditAnywhere)
	int ArmAmount = 54;

	UPROPERTY(EditAnywhere)
	float ArmVerticalOffset = 150.0;

	UPROPERTY(EditAnywhere)
	float AnglePerArm = 20.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			UPrisonPerchSpiralPlayerComponent PlayerComp = UPrisonPerchSpiralPlayerComponent::Create(Player);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SpiralRoot.AddLocalRotation(FRotator(0.0, RotationSpeed * DeltaTime, 0.0));

		TopOffset -= SinkSpeed * DeltaTime;
		TopSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, TopOffset));
		if (TopOffset <= -2000.0)
		{
			TopOffset = 4000.0;
			TopSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, 4000.0));
		}
		
		MiddleOffset -= SinkSpeed * DeltaTime;
		MiddleSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, MiddleOffset));
		if (MiddleOffset <= -2000.0)
		{
			MiddleOffset = 4000.0;
			MiddleSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, 4000.0));
		}

		BottomOffset -= SinkSpeed * DeltaTime;
		BottomSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, BottomOffset));
		if (BottomOffset <= -2000.0)
		{
			BottomOffset = 4000.0;
			BottomSpiralRoot.SetRelativeLocation(FVector(0.0, 0.0, 4000.0));
		}
	}

	UFUNCTION(CallInEditor)
	void SpawnArms()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			APrisonPerchSpiralArm Arm = Cast<APrisonPerchSpiralArm>(Actor);
			if (Arm != nullptr)
				Arm.DestroyActor();
		}

		DisableComp.AutoDisableLinkedActors.Reset();

		for (int i = 0; i < ArmAmount; i++)
		{
			APrisonPerchSpiralArm Arm = SpawnActor(ArmClass);
			Arm.AttachToComponent(SpiralRoot);
			FHitResult DummyHit;
			Arm.SetActorRelativeRotation(FRotator(0.0, i * -AnglePerArm, 0.0), false, DummyHit, false);
			Arm.SetActorRelativeLocation(FVector(0.0, 0.0, -2000.0 + (i * ArmVerticalOffset)), false, DummyHit, false);
			Arm.UpdateHeight(-2000.0 + (i * ArmVerticalOffset));

			DisableComp.AutoDisableLinkedActors.Add(Arm);
		}
	}

	UFUNCTION(CallInEditor)
	void AddAllArmsToDisableLinkedActors()
	{
		DisableComp.AutoDisableLinkedActors.Reset();
		
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		for(auto Actor : AttachedActors)
		{
			APrisonPerchSpiralArm Arm = Cast<APrisonPerchSpiralArm>(Actor);
			if(Arm != nullptr)
				DisableComp.AutoDisableLinkedActors.Add(Arm);
		}
	}

	UFUNCTION()
	void SetPoiEnabledForPlayer(AHazePlayerCharacter Player, bool bEnabled)
	{
		UPrisonPerchSpiralPlayerComponent Comp = UPrisonPerchSpiralPlayerComponent::GetOrCreate(Player);
		Comp.SetPoiEnabled(bEnabled);
	}
}

UCLASS(Abstract)
class APrisonPerchSpiralArm: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	USceneComponent PerchRoot;

	UPROPERTY(DefaultComponent, Attach = PerchRoot)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterComp;

	UPROPERTY(EditAnywhere)
	float Height = 0.0;

	FTransform StartingRelativeTransform;
	bool bInteractible = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PerchPointComp.OnPlayerInitiatedJumpToEvent.AddUFunction(this, n"StartJumpTo");
		PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StoppedPerching");

		if (AttachParentActor != nullptr)
			AddTickPrerequisiteActor(AttachParentActor);

		StartingRelativeTransform = GetActorRelativeTransform();

		FTransform WorldTransform = GetActorTransform();
		RootComp.SetAbsolute(true, true, true);
		SetActorTransform(WorldTransform);
	}

	UFUNCTION()
	private void StartJumpTo(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		UPrisonPerchSpiralPlayerComponent PlayerComp = UPrisonPerchSpiralPlayerComponent::Get(Player);
		if (!PlayerComp.bUsePoi)
			return;

		FHazePointOfInterestFocusTargetInfo PoIInfo;
		FVector Dir = (PerchPoint.WorldLocation - Player.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		float Dot = Dir.DotProduct(PerchPoint.ForwardVector);

		FVector FocusLoc = PerchPointComp.WorldLocation + (PerchPointComp.ForwardVector * (Dot > 0.0 ? 4000.0 : -2000.0));
		FocusLoc += PerchPoint.RightVector * -400.0;
		FocusLoc += FVector::UpVector * -200.0;
		PoIInfo.SetFocusToWorldLocation(FocusLoc);

		FApplyPointOfInterestSettings PoISettings;
		PoISettings.Duration = 0.0;

		Player.ApplyPointOfInterest(this, PoIInfo, PoISettings, 1.5, EHazeCameraPriority::Medium);
	}

	UFUNCTION()
	private void StoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		Player.ClearPointOfInterestByInstigator(this);
	}

	void UpdateHeight(float NewHeight)
	{
		Height = NewHeight;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Height -= 15.0 * DeltaTime;
		FVector Location = FVector(0.0, 0.0, Height);

		if (Height <= -2000.0)
		{
			Height = 4000.0;
			Location = FVector(0.0, 0.0, 4000.0);
		}

		if (Math::IsWithin(Height, -400, 800))
		{
			// Debug::DrawDebugSphere(PerchPointComp.WorldLocation);

			if (!bInteractible)
			{
				TArray<UStaticMeshComponent> MeshComps;
				GetComponentsByClass(MeshComps);
				
				for (auto Mesh : MeshComps)
					Mesh.SetCastShadow(true);

				RemoveActorCollisionBlock(this);
				bInteractible = true;
			}
		}
		else
		{
			if (bInteractible)
			{
				TArray<UStaticMeshComponent> MeshComps;
				GetComponentsByClass(MeshComps);
				
				for (auto Mesh : MeshComps)
					Mesh.SetCastShadow(false);

				AddActorCollisionBlock(this);
				bInteractible = false;
			}
		}

		FTransform ParentTransform = RootComp.AttachParent.WorldTransform;
		FTransform RelativeTransform = StartingRelativeTransform;
		RelativeTransform.SetLocation(Location);
		ActorTransform = FTransform::ApplyRelative(ParentTransform, RelativeTransform);
	}
}

class UPrisonPerchSpiralPlayerComponent : UActorComponent
{
	bool bUsePoi = true;

	void SetPoiEnabled(bool bEnabled)
	{
		bUsePoi = bEnabled;
	}
}