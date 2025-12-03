struct FIslandRedBlueWeaponComponentData
{
	AIslandRedBlueWeapon Weapon;

	UPROPERTY()
	FName HandAttachSocket;

	UPROPERTY()
	FTransform HandAttachRelativeOffset = FTransform::Identity;

	UPROPERTY()
	FName ThighAttachSocket;

	UPROPERTY()
	FTransform ThighAttachRelativeOffset = FTransform::Identity;
}

struct FIslandRedBlueWeaponAnimData
{
	private FVector Internal_AimDirection;
	
	private bool bAimDirectionOverridden;
	private float OverrideBlendDuration;
	private FVector OverrideAimDirection;
	private FInstigator OverrideAimInstigator;
	private TOptional<float> TimeOfOverrideAimDirection;

	uint LastFrameWeAimed;
	bool bShotThisTickLeft;
	bool bShotThisTickRight;
	bool bShotGrenadeThisTickLeft;
	bool bShotGrenadeThisTickRight;
	bool bDetonatingHeldWeapons;
	bool bDetonatingLeftGrenade;
	bool bDetonatingRightGrenade;
	bool bIsOverheated;

	bool IsAimingThisFrame() const
	{
		return Time::FrameNumber == LastFrameWeAimed;
	}

	void SetAimDirection(FVector Value) property
	{
		Internal_AimDirection = Value;
	}

	FVector GetAimDirection() const property
	{
		FVector Direction = Internal_AimDirection;
		if(TimeOfOverrideAimDirection.IsSet())
		{
			FVector A = bAimDirectionOverridden ? Direction : OverrideAimDirection;
			FVector B = bAimDirectionOverridden ? OverrideAimDirection : Direction;
			float TimeSince = Time::GetGameTimeSince(TimeOfOverrideAimDirection.Value);
			if(OverrideBlendDuration <= 0.0)
				return B;
			
			float Slerp = TimeSince / OverrideBlendDuration;
			Slerp = Math::Saturate(Slerp);
			Slerp = Math::EaseInOut(0.0, 1.0, Slerp, 2.0);
			Direction = FQuat::Slerp(A.ToOrientationQuat(), B.ToOrientationQuat(), Slerp).ForwardVector;
		}

		return Direction;
	}

	void ApplyOverriddenAimDirection(FVector Direction, FInstigator Instigator, float BlendDuration = 0.2)
	{
		devCheck(!bAimDirectionOverridden || Instigator == OverrideAimInstigator, "Tried to apply overridden aim direction when it is already overridden by another instigator, this is not supported");
		OverrideAimDirection = Direction;
		OverrideAimInstigator = Instigator;
		OverrideBlendDuration = BlendDuration;

		if(!bAimDirectionOverridden)
			TimeOfOverrideAimDirection.Set(Time::GetGameTimeSeconds());

		bAimDirectionOverridden = true;
	}

	void ClearOverriddenAimDirection(FInstigator Instigator)
	{
		if(!bAimDirectionOverridden)
			return;

		devCheck(Instigator == OverrideAimInstigator, "Cannot clear overridden aim direction since we haven't overridden aim direction with this instigator!");

		bAimDirectionOverridden = false;
		TimeOfOverrideAimDirection.Set(Time::GetGameTimeSeconds());
	}

	bool HasOverriddenAimDirection(FInstigator Instigator)
	{
		return bAimDirectionOverridden && Instigator == OverrideAimInstigator;
	}
}

struct FIslandRedBlueWeaponHandBlockers
{
	TArray<FInstigator> Blockers;

	bool IsBlocked() const
	{
		return Blockers.Num() > 0;
	}
}

enum EIslandRedBlueWeaponMeshType
{
	DefaultWeapon,
	GrenadeAttachmentWeapon
}

struct FIslandRedBlueBufferedImpactData
{
	FIslandRedBlueBufferedImpactData(UIslandRedBlueImpactResponseComponent In_ResponseComp)
	{
		ResponseComp = In_ResponseComp;
	}

	UIslandRedBlueImpactResponseComponent ResponseComp;
	float Damage = 0.0;
	FVector BulletShootDirection;
	FHitResult Hit;

	bool opEquals(FIslandRedBlueBufferedImpactData Other) const
	{
		return ResponseComp == Other.ResponseComp;
	}
}

struct FIslandRedBlueWeaponBulletClass
{
	FIslandRedBlueWeaponBulletClass(TSubclassOf<AIslandRedBlueWeaponBullet> In_Class)
	{
		Class = In_Class;
	}

	TSubclassOf<AIslandRedBlueWeaponBullet> Class;
}

UCLASS(Abstract)
class UIslandRedBlueWeaponUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	access BlockWeaponCapabilities = private, UIslandRedBlueWallRunBlockWeaponCapability, UIslandRedBlueSwingBlockWeaponCapability, UIslandRedBlueSlideBlockWeaponCapability, UIslandRedBlueContextualBlockBothWeaponsCapability, UIslandWalkerHeadHatchInteractionCapability;

	UPROPERTY(Category = "Settings")
	private EIslandRedBlueWeaponType WeaponType = EIslandRedBlueWeaponType::MAX;

	UPROPERTY(Category = "Settings")
	private TSubclassOf<AIslandRedBlueWeapon> WeaponClass;

	UPROPERTY(Category = "Settings")
	private UStaticMesh WeaponAttachmentMesh;

	UPROPERTY(Category = "Settings")
	TSubclassOf<AIslandRedBlueWeaponBullet> BulletClass;

	UPROPERTY(Category = "Settings")
	TSubclassOf<AIslandRedBlueWeaponBullet> BulletSidescrollerClass;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<AIslandRedBlueSidescrollerSpotlightActor> SpotlightActorClass;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UTargetableWidget> DefaultAimWidget;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UTargetableWidget> Default2DAimWidget;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UIslandRedBlueAimCrosshairWidget> CrosshairWidget;

	UPROPERTY(Category = "Settings")
	TSubclassOf<UIslandRedBlueOverheat2DWidget> Overheat2DWidget;

	UPROPERTY(Category = "Settings")
	UPlayerHealthSettings HealthSettings;
	
	UPROPERTY(Category = "Settings", AdvancedDisplay)
	private TArray<FIslandRedBlueWeaponComponentData> WeaponInternals;
	default WeaponInternals.SetNum(EIslandRedBlueWeaponHandType::MAX);

	UPROPERTY(Category = "Settings")
	UPlayerAimingSettings AimSettings;

	UPROPERTY(Category = "Settings")
	UNiagaraSystem ImpactFlashSystem;
	
	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].HandAttachSocket = n"LeftAttach";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].HandAttachSocket = n"RightAttach";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].HandAttachRelativeOffset = FTransform(FRotator(0, -90, 90));
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].HandAttachRelativeOffset = FTransform(FRotator(0, -90, 90));

	default WeaponInternals[EIslandRedBlueWeaponHandType::Left].ThighAttachSocket = n"LeftLegGunAttachSocket";
	default WeaponInternals[EIslandRedBlueWeaponHandType::Right].ThighAttachSocket = n"RightLegGunAttachSocket";
	// Since the guns now have their own mesh socket the below offsets aren't needed, they are simply baked into the socket's relative location.
	//default WeaponInternals[EIslandRedBlueWeaponHandType::Left].ThighAttachRelativeOffset = FTransform(FRotator(90, 19.188477, 18.350379), FVector(0.146, -9.999, 10.911));
	//default WeaponInternals[EIslandRedBlueWeaponHandType::Right].ThighAttachRelativeOffset = FTransform(FRotator(90, -160.503266, -159.962864), FVector(0.094, 10.000, 10.911));

	private AHazePlayerCharacter PlayerOwner;
	access:BlockWeaponCapabilities EIslandRedBlueWeaponAttachSocketType CurrentAttachType = EIslandRedBlueWeaponAttachSocketType::UnEquipped;
	private TInstigated<bool> bHasEquippedWeapons;
	private UIslandRedBlueWeaponSettings ActiveSettings;
	private UPlayerAimingComponent AimComp;
	private UCameraSettings CameraSettings;

	TArray<FInstigator> FireWeaponsInstigators;
	TArray<FInstigator> AimInstigators;
	private TArray<FInstigator> HoldInHandsInstigators;
	EIslandRedBlueWeaponHandType LastWeaponFired = EIslandRedBlueWeaponHandType::Left;
	float NextShootDelayTimeLeft = 0;
	FIslandRedBlueWeaponAnimData WeaponAnimData;
	float TimeOfStartShooting = -1.0;
	TOptional<float> TimeOfUnblockWeaponsFromAnimation;
	bool bIsLeftGrenadeAnimRunning = false;
	bool bIsRightGrenadeAnimRunning = false;
	TOptional<float> TimeOfLeftGrenadeAnimStopped;
	TOptional<float> TimeOfRightGrenadeAnimStopped;
	private EIslandRedBlueWeaponUpgradeType Internal_CurrentUpgradeType = EIslandRedBlueWeaponUpgradeType::OverheatAssault;
	private TMap<EIslandRedBlueWeaponHandType, FIslandRedBlueWeaponHandBlockers> HandBlockers;
	private TInstigated<USceneComponent> InstigatedForcedTarget;
	private TArray<FInstigator> ShowOverheat2DWidgetInstigators;
	private TArray<FInstigator> OverrideFeatureBlockers;
	private TArray<FInstigator> ForceHoldWeaponInHandInstigators;
	private TArray<FInstigator> BlockCameraAssistanceInstigators;
	private bool bHasBegunPlay = false;
	private EIslandRedBlueWeaponMeshType CurrentMeshType = EIslandRedBlueWeaponMeshType::DefaultWeapon;
	private UStaticMesh DefaultWeaponMesh;
	private TArray<UMaterialInterface> WeaponMaterials;
	private TInstigated<FIslandRedBlueWeaponBulletClass> InstigatedOverrideBulletClass;

	const float NetMaxImpactsPerSecond = 10.0;
	private float TimeOfLastBulletImpact = -100.0;
	private TArray<FIslandRedBlueBufferedImpactData> NetBufferedImpacts;

	private UNiagaraComponent ImpactFlashLight;
	const bool bUseOutlines = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HandBlockers.Add(EIslandRedBlueWeaponHandType::Left, FIslandRedBlueWeaponHandBlockers());
		HandBlockers.Add(EIslandRedBlueWeaponHandType::Right, FIslandRedBlueWeaponHandBlockers());

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		AimComp = UPlayerAimingComponent::Get(PlayerOwner);
		CameraSettings = UCameraSettings::GetSettings(PlayerOwner);

		PlayerOwner.ApplySettings(AimSettings, this);
		ActiveSettings = UIslandRedBlueWeaponSettings::GetSettings(PlayerOwner);

		ImpactFlashLight = UNiagaraComponent::Create(Game::DynamicSpawnWorldSettings);
		ImpactFlashLight.SetAutoActivate(false);
		ImpactFlashLight.SetAsset(ImpactFlashSystem);

		// Spawn Left Hand
		{
			auto Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true);
			InitializeWeapon(Weapon, EIslandRedBlueWeaponHandType::Left);
		}

		// Spawn Right Hand
		{
			auto Weapon = SpawnActor(WeaponClass, bDeferredSpawn = true);
			InitializeWeapon(Weapon, EIslandRedBlueWeaponHandType::Right);
		}

		if(ActiveSettings.bStartWithEquippedWeapons)
		{
			EquipWeapons(this, EInstigatePriority::Level);
		}

		FHazeDevInputInfo SwitchInputInfo;
		SwitchInputInfo.Name = n"Switch Weapon Upgrade Type";
		SwitchInputInfo.Category = n"Island";
		SwitchInputInfo.OnTriggered.BindUFunction(this, n"HandleDevSwitchWeaponUpgradeType");
		SwitchInputInfo.OnStatus.BindUFunction(this, n"OnDevWeaponUpgradeTypeStatus");
		SwitchInputInfo.AddKey(EKeys::Gamepad_FaceButton_Top);
		SwitchInputInfo.AddKey(EKeys::Y);

		PlayerOwner.RegisterDevInput(SwitchInputInfo);
		bHasBegunPlay = true;
	}

	void AddImpactFlash(FVector Point)
	{
		if (!ImpactFlashLight.IsActive())
		{
			ImpactFlashLight.SetWorldLocation(Point);
			ImpactFlashLight.Activate(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CanApplyImpactNow() && NetBufferedImpacts.Num() != 0)
		{
			FIslandRedBlueBufferedImpactData Data = NetBufferedImpacts[0];
			if(Data.ResponseComp != nullptr && Data.ResponseComp.CanApplyImpact(PlayerOwner, Data.Hit))
			{
				Internal_ApplyImpactRemote(Data.BulletShootDirection, Data.ResponseComp, Data.Hit, Data.Damage);
			}

			NetBufferedImpacts.RemoveAt(0);
		}

		if(NetBufferedImpacts.Num() == 0)
			SetComponentTickEnabled(false);
	}

	bool IsLeftGrenadeAnimRunning() const
	{
		if(bIsLeftGrenadeAnimRunning)
			return true;

		if(TimeOfLeftGrenadeAnimStopped.IsSet() && Time::GetGameTimeSince(TimeOfLeftGrenadeAnimStopped.Value) < 0.5)
			return true;

		return false;
	}

	bool IsRightGrenadeAnimRunning() const
	{
		if(bIsRightGrenadeAnimRunning)
			return true;

		if(TimeOfRightGrenadeAnimStopped.IsSet() && Time::GetGameTimeSince(TimeOfRightGrenadeAnimStopped.Value) < 0.5)
			return true;

		return false;
	}

	TSubclassOf<AIslandRedBlueWeaponBullet> GetRelevantBulletClass() const
	{
		if(!InstigatedOverrideBulletClass.IsDefaultValue())
			return InstigatedOverrideBulletClass.Get().Class;

		if(AimComp.HasAiming2DConstraint())
			return BulletSidescrollerClass;

		return BulletClass;
	}

	void ApplyOverrideBulletClass(TSubclassOf<AIslandRedBlueWeaponBullet> OverrideClass, FInstigator Instigator)
	{
		InstigatedOverrideBulletClass.Apply(FIslandRedBlueWeaponBulletClass(OverrideClass), Instigator);
	}

	void ClearOverrideBulletClass(FInstigator Instigator)
	{
		InstigatedOverrideBulletClass.Clear(Instigator);
	}

	UFUNCTION()
	private void HandleDevSwitchWeaponUpgradeType()
	{
		CurrentUpgradeType = EIslandRedBlueWeaponUpgradeType((int(CurrentUpgradeType) + 1) % int(EIslandRedBlueWeaponUpgradeType::MAX));
		Print(f"New weapon upgrade type (for both players): {GetCleanCurrentUpgradeTypeString()}");
		UIslandRedBlueWeaponUserComponent::Get(PlayerOwner.OtherPlayer).CurrentUpgradeType = CurrentUpgradeType;
	}

	UFUNCTION()
	private void OnDevWeaponUpgradeTypeStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		OutDescription = GetCleanCurrentUpgradeTypeString();
		OutColor = FLinearColor::Green;
	}

	private FString GetCleanCurrentUpgradeTypeString() const
	{
		FString UpgradeType = f"{CurrentUpgradeType}";
		FString Junk;
		UpgradeType.Split("::", Junk, UpgradeType, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		UpgradeType.Split(" ", UpgradeType, Junk, ESearchCase::IgnoreCase, ESearchDir::FromEnd);
		return UpgradeType;
	}

	private void InitializeWeapon(AIslandRedBlueWeapon Weapon, EIslandRedBlueWeaponHandType Hand)
	{
		Weapon.WeaponType = WeaponType;
		Weapon.HandType = Hand;
		Weapon.PlayerOwner = PlayerOwner;
		Outline::AddToPlayerOutlineActor(Weapon, PlayerOwner, this, EInstigatePriority::Level);
		Weapon.AddActorDisable(this);
		WeaponInternals[Hand].Weapon = Weapon;
		FinishSpawningActor(Weapon);
		DefaultWeaponMesh = Weapon.Mesh.StaticMesh;
		WeaponMaterials = Weapon.Mesh.Materials;
	}

	void SwitchWeaponMesh(EIslandRedBlueWeaponMeshType WeaponMeshType)
	{
		devCheck(bHasBegunPlay, "We can't switch weapon class before BeginPlay has been run!");
		if(WeaponMeshType == CurrentMeshType)
			return;

		UStaticMesh Mesh = GetWeaponMeshFromType(WeaponMeshType);
		for(auto Weapon : WeaponInternals)
		{
			// In case weapons don't exist because of level load.
			if(Weapon.Weapon == nullptr)
				continue;

			Weapon.Weapon.Mesh.StaticMesh = Mesh;
			for(int i = 0; i < WeaponMaterials.Num(); i++)
			{
				Weapon.Weapon.Mesh.SetMaterial(0, WeaponMaterials[i]);
			}
		}
		CurrentMeshType = WeaponMeshType;
	}

	UStaticMesh GetWeaponMeshFromType(EIslandRedBlueWeaponMeshType MeshType) const
	{
		switch(MeshType)
		{
			case EIslandRedBlueWeaponMeshType::DefaultWeapon:
				return DefaultWeaponMesh;
			case EIslandRedBlueWeaponMeshType::GrenadeAttachmentWeapon:
				return WeaponAttachmentMesh;
		}
	}

	void ApplyForcedTarget(USceneComponent Target, FInstigator Instigator, bool bAlsoApplyForced2DOverheatWidget = true, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedForcedTarget.Apply(Target, Instigator, Priority);
		if(bAlsoApplyForced2DOverheatWidget)
			ApplyForced2DOverheatWidget(Instigator);
	}

	void ClearForcedTarget(FInstigator Instigator, bool bAlsoClearForced2DOverheatWidget = true)
	{
		InstigatedForcedTarget.Clear(Instigator);
		if(bAlsoClearForced2DOverheatWidget)
			ClearForced2DOverheatWidget(Instigator);
	}

	bool HasForcedTarget() const
	{
		return !InstigatedForcedTarget.IsDefaultValue();
	}

	void AddOverrideFeatureBlocker(FInstigator Instigator)
	{
		OverrideFeatureBlockers.AddUnique(Instigator);
	}

	void RemoveOverrideFeatureBlocker(FInstigator Instigator)
	{
		OverrideFeatureBlockers.RemoveSingleSwap(Instigator);
	}

	bool IsOverrideFeatureBlocked() const
	{
		return OverrideFeatureBlockers.Num() > 0;
	}

	void AddForceHoldWeaponInHandInstigator(FInstigator Instigator)
	{
		ForceHoldWeaponInHandInstigators.AddUnique(Instigator);
	}

	void RemoveForceHoldWeaponInHandInstigator(FInstigator Instigator)
	{
		ForceHoldWeaponInHandInstigators.RemoveSingleSwap(Instigator);
	}

	bool ShouldForceHoldWeaponInHand() const
	{
		return ForceHoldWeaponInHandInstigators.Num() > 0;
	}

	void ApplyForced2DOverheatWidget(FInstigator Instigator)
	{
		ShowOverheat2DWidgetInstigators.AddUnique(Instigator);
	}

	void ClearForced2DOverheatWidget(FInstigator Instigator)
	{
		ShowOverheat2DWidgetInstigators.RemoveSingleSwap(Instigator);
	}

	bool Is2DOverheatWidgetForced() const
	{
		return ShowOverheat2DWidgetInstigators.Num() > 0;
	}

	bool IsRedPlayer() const
	{
		return WeaponType == EIslandRedBlueWeaponType::Red;
	}

	bool IsBluePlayer() const
	{
		return WeaponType == EIslandRedBlueWeaponType::Blue;
	}

	AIslandRedBlueWeapon GetWeapon(EIslandRedBlueWeaponHandType Hand) const
	{
		return WeaponInternals[Hand].Weapon;
	}

	AIslandRedBlueWeapon GetLeftWeapon() const property
	{
		return WeaponInternals[EIslandRedBlueWeaponHandType::Left].Weapon;
	}

	AIslandRedBlueWeapon GetRightWeapon() const property
	{
		return WeaponInternals[EIslandRedBlueWeaponHandType::Right].Weapon;
	}

	TArray<AIslandRedBlueWeapon> GetWeapons() const property
	{
		TArray<AIslandRedBlueWeapon> OutWeapons;
		for(const auto& It : WeaponInternals)
		{
			OutWeapons.Add(It.Weapon);
		}
		return OutWeapons;
	}

	void EquipWeapons(FInstigator Instigator, EInstigatePriority Priority)
	{
		const bool bPrevEquipped = bHasEquippedWeapons.Get();
		bHasEquippedWeapons.Apply(true, Instigator, Priority);
		const bool bEquipped = bHasEquippedWeapons.Get();

		if(bPrevEquipped == bEquipped)
			return;
		
		for(auto It : WeaponInternals)
		{
			auto Weapon = It.Weapon;
			Weapon.RemoveActorDisable(this);
		}

		Internal_AttachWeaponToThigh();
		
		FHazeActiveCameraClampSettings ActiveClamps;
		CameraSettings.Clamps.GetClamps(ActiveClamps);
		FHazeCameraClampSettings Clamps;
		Clamps.ApplyUnclamped();
		Clamps.ApplyClampsPitch(ActiveClamps.PitchUp.Value, 85);
		CameraSettings.Clamps.Apply(Clamps, this, 0.0, EHazeCameraPriority::High);
	}

	void UnEquipWeapons(FInstigator Instigator)
	{
		const bool bPrevEquipped = bHasEquippedWeapons.Get();
		bHasEquippedWeapons.Clear(Instigator);
		const bool bEquipped = bHasEquippedWeapons.Get();

		if(bPrevEquipped == bEquipped)
			return;
		
		CurrentAttachType = EIslandRedBlueWeaponAttachSocketType::UnEquipped;
		for(auto It : WeaponInternals)
		{
			It.Weapon.AddActorDisable(this);
		}

		CameraSettings.Clamps.Clear(this);
	}

	// Will disable both weapons, mostly used for cutscenes
	void AddWeaponDisable(FInstigator Instigator)
	{
		for(auto It : WeaponInternals)
		{
			It.Weapon.AddActorDisable(Instigator);
		}
	}

	// Will remove a previous disable for both weapons, mostly used for cutscenes
	void RemoveWeaponDisable(FInstigator Instigator)
	{
		for(auto It : WeaponInternals)
		{
			It.Weapon.RemoveActorDisable(Instigator);
		}
	}

	// Will disable a specific weapon, mostly used for cutscenes
	void AddSpecificWeaponDisable(EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		WeaponInternals[Hand].Weapon.AddActorDisable(Instigator);
	}

	// Will remove a previous disable for a specific weapon, mostly used for cutscenes
	void RemoveSpecificWeaponDisable(EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		WeaponInternals[Hand].Weapon.RemoveActorDisable(Instigator);
	}

	bool HasEquippedWeapons() const
	{
		return bHasEquippedWeapons.Get();
	}

	void AddBlockCameraAssistanceInstigator(FInstigator Instigator)
	{
		BlockCameraAssistanceInstigators.AddUnique(Instigator);
	}

	void RemoveBlockCameraAssistanceInstigator(FInstigator Instigator)
	{
		BlockCameraAssistanceInstigators.RemoveSingleSwap(Instigator);
	}

	bool HasBlockCameraAssistanceInstigator() const
	{
		return BlockCameraAssistanceInstigators.Num() > 0;
	}

	void AttachWeaponToThigh(FInstigator Instigator)
	{
		bool bPrevHoldInHands = HasHoldInHandsInstigator();
		HoldInHandsInstigators.RemoveSingleSwap(Instigator);
		bool bHoldInHands = HasHoldInHandsInstigator();

		if(bPrevHoldInHands == bHoldInHands)
			return;

		Internal_AttachWeaponToThigh();
	}

	private void Internal_AttachWeaponToThigh()
	{
		devCheck(CurrentAttachType != EIslandRedBlueWeaponAttachSocketType::AttachToThigh, "Tried to attach weapon to thigh when it is already attached to the thigh!");
		CurrentAttachType = EIslandRedBlueWeaponAttachSocketType::AttachToThigh;
		
		Internal_AttachSpecificWeaponToThigh(EIslandRedBlueWeaponHandType::Left);
		Internal_AttachSpecificWeaponToThigh(EIslandRedBlueWeaponHandType::Right);
	}

	private void Internal_AttachSpecificWeaponToThigh(EIslandRedBlueWeaponHandType Hand)
	{
		FIslandRedBlueWeaponComponentData Data = WeaponInternals[Hand];
		Data.Weapon.AttachToComponent(PlayerOwner.Mesh, Data.ThighAttachSocket);
		Data.Weapon.SetActorRelativeTransform(Data.ThighAttachRelativeOffset);
		UIslandRedBlueWeaponEffectHandler::Trigger_OnWeaponAttachToThigh(WeaponInternals[Hand].Weapon);
	}

	void AttachWeaponToHand(FInstigator Instigator)
	{
		bool bPrevHoldInHands = HasHoldInHandsInstigator();
		HoldInHandsInstigators.AddUnique(Instigator);
		bool bHoldInHands = HasHoldInHandsInstigator();

		if(bPrevHoldInHands == bHoldInHands)
			return;

		Internal_AttachWeaponToHand();
	}

	private void Internal_AttachWeaponToHand()
	{
		devCheck(CurrentAttachType != EIslandRedBlueWeaponAttachSocketType::AttachToHand, "Tried to attach weapon to hands when it is already attached to the hands!");
		CurrentAttachType = EIslandRedBlueWeaponAttachSocketType::AttachToHand;
		
		if(!IsHandBlocked(EIslandRedBlueWeaponHandType::Left))
			Internal_AttachSpecificWeaponToHand(EIslandRedBlueWeaponHandType::Left);

		if(!IsHandBlocked(EIslandRedBlueWeaponHandType::Right))
			Internal_AttachSpecificWeaponToHand(EIslandRedBlueWeaponHandType::Right);
	}

	private void Internal_AttachSpecificWeaponToHand(EIslandRedBlueWeaponHandType Hand)
	{
		FIslandRedBlueWeaponComponentData Data = WeaponInternals[Hand];
		Data.Weapon.AttachToComponent(PlayerOwner.Mesh, Data.HandAttachSocket);
		Data.Weapon.SetActorRelativeTransform(Data.HandAttachRelativeOffset);
		UIslandRedBlueWeaponEffectHandler::Trigger_OnWeaponAttachToHand(WeaponInternals[Hand].Weapon);
	}

	private bool HasHoldInHandsInstigator()
	{
		return HoldInHandsInstigators.Num() > 0;
	}

	bool HasWeaponsInHands() const
	{
		return CurrentAttachType == EIslandRedBlueWeaponAttachSocketType::AttachToHand;
	}

	bool IsAiming() const
	{
		return AimInstigators.Num() > 0;
	}

	bool WantsToFireWeapon() const
	{
		return FireWeaponsInstigators.Num() > 0;
	}

	EIslandRedBlueWeaponType GetWeaponColor() const property
	{
		return WeaponType;
	}

	UFUNCTION()
	void SetCurrentUpgradeType(EIslandRedBlueWeaponUpgradeType UpgradeType) property
	{
		Internal_CurrentUpgradeType = UpgradeType;
	}

	UFUNCTION()
	EIslandRedBlueWeaponUpgradeType GetCurrentUpgradeType() const property
	{
		return Internal_CurrentUpgradeType;
	}

	access:BlockWeaponCapabilities void AddHandBlocker(EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		bool bHandIsBlocked = IsHandBlocked(Hand);
		if(!bHandIsBlocked && CurrentAttachType == EIslandRedBlueWeaponAttachSocketType::AttachToHand)
			Internal_AttachSpecificWeaponToThigh(Hand);

		HandBlockers[Hand].Blockers.AddUnique(Instigator);
	}

	access:BlockWeaponCapabilities void RemoveHandBlocker(EIslandRedBlueWeaponHandType Hand, FInstigator Instigator)
	{
		bool bHandIsBlocked = IsHandBlocked(Hand);
		HandBlockers[Hand].Blockers.RemoveSingleSwap(Instigator);
		bool bNewHandIsBlocked = IsHandBlocked(Hand);

		if(CurrentAttachType == EIslandRedBlueWeaponAttachSocketType::AttachToHand && bHandIsBlocked && !bNewHandIsBlocked)
			Internal_AttachSpecificWeaponToHand(Hand);
	}

	bool IsHandBlocked(EIslandRedBlueWeaponHandType HandType) const
	{
		if(HandType == EIslandRedBlueWeaponHandType::Left)
			return IsLeftHandBlocked();
		else if(HandType == EIslandRedBlueWeaponHandType::Right)
			return IsRightHandBlocked();
		else
			devError("Forgot to add case");

		return false;
	}

	bool IsAnyHandBlocked() const
	{
		return IsLeftHandBlocked() || IsRightHandBlocked();
	}

	bool IsLeftHandBlocked() const
	{
		return HandBlockers[EIslandRedBlueWeaponHandType::Left].IsBlocked();
	}

	bool IsRightHandBlocked() const
	{
		return HandBlockers[EIslandRedBlueWeaponHandType::Right].IsBlocked();
	}

	FAimingResult GetAimTarget()
	{
		FAimingResult AimTarget;
		USceneComponent ForcedTarget = InstigatedForcedTarget.Get();
		if(ForcedTarget != nullptr)
		{
			AimTarget.AimOrigin = PlayerOwner.ActorCenterLocation;
			AimTarget.AimDirection = (ForcedTarget.WorldLocation - AimTarget.AimOrigin).GetSafeNormal();
		}
		else if(AimComp.IsAiming(this))
		{
			if(AimComp.HasAiming2DConstraint())
			{
				FAimingRay Ray = AimComp.GetPlayerAimingRay();
				AimTarget.AimOrigin = Ray.Origin;
				AimTarget.AimDirection = Ray.Direction;
			}
			else
			{
				AimTarget = AimComp.GetAimingTarget(this);
			}
		}
		else
		{
			AimTarget.AimOrigin = PlayerOwner.ViewLocation;
			AimTarget.AimDirection = (PlayerOwner.ViewRotation.Quaternion() * FRotator(15, 0, 0).Quaternion()).ForwardVector;
		}

		return AimTarget;
	}

	FVector GetBulletTargetLocation(FHitResult&out OutHit)
	{
		FAimingResult AimTarget = GetAimTarget();
		return GetBulletTargetLocation(OutHit, AimTarget);
	}

	FVector GetBulletTargetLocation(FHitResult&out OutHit, FAimingResult AimTarget)
	{
		FVector BulletTarget = AimTarget.AimOrigin + AimTarget.AimDirection * ActiveSettings.WeaponMaxTraceLength;
		OutHit = QueryBulletImpact(AimTarget);

		if(OutHit.bBlockingHit)
		{
			BulletTarget = OutHit.ImpactPoint;
		}

		return BulletTarget;
	}

	FHitResult QueryBulletImpact(FAimingResult AimTarget)
	{
		auto Trace = Trace::InitChannel(ActiveSettings.TraceChannel);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(LeftWeapon);
		Trace.IgnoreActor(RightWeapon);
		Trace.UseLine();
		
		FVector TraceEnd;
		if (AimTarget.AutoAimTarget != nullptr)
		{
			auto TargetComponent = Cast<UIslandRedBlueTargetableComponent>(AimTarget.AutoAimTarget);
			if(TargetComponent != nullptr)
			{
				TraceEnd = TargetComponent.GetTargetLocation(PlayerOwner);
			}
			else
			{
				TraceEnd = TargetComponent.GetWorldLocation();
			}
		}
		else
		{
			TraceEnd = AimTarget.AimOrigin + (AimTarget.AimDirection * ActiveSettings.WeaponMaxTraceLength);
		}

		FVector TraceStart = AimTarget.AimOrigin;
		
		auto Hits = Trace.QueryTraceMulti(TraceStart, TraceEnd);
		for(auto Hit : Hits)
		{
			if(IslandRedBlueWeapon::CurrentCameraWeaponTraceHitIsValid(PlayerOwner, Hit, this))
				return Hit;
		}

		auto BasicHit = FHitResult();
		BasicHit.TraceStart = TraceStart;
		BasicHit.TraceEnd = TraceEnd;
		return BasicHit;
	}

	private void Internal_ApplyImpactRemote(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		CrumbApplyImpactRemote(BulletShootDirection, Response, Hit, BulletDamageMultiplier);
		TimeOfLastBulletImpact = Time::GetGameTimeSeconds();
	}

	private void Internal_ApplyImpact(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		CrumbApplyImpact(BulletShootDirection, Response, Hit, BulletDamageMultiplier);
		TimeOfLastBulletImpact = Time::GetGameTimeSeconds();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbApplyImpactRemote(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		// Control side impacts always happen instantly, this function is only called to buffer impacts on the remote side.
		if(HasControl())
			return;

		Response.ApplyImpact(BulletShootDirection, PlayerOwner, Hit, BulletDamageMultiplier);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbApplyImpact(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		Response.ApplyImpact(BulletShootDirection, PlayerOwner, Hit, BulletDamageMultiplier);
	}

	void ApplyImpact(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		if(CanApplyImpactNow())
		{
			Internal_ApplyImpact(BulletShootDirection, Response, Hit, BulletDamageMultiplier);
		}
		else
		{
			BufferImpact(BulletShootDirection, Response, Hit, BulletDamageMultiplier);
		}
	}

	void BufferImpact(FVector BulletShootDirection, UIslandRedBlueImpactResponseComponent Response, FHitResult Hit, float BulletDamageMultiplier)
	{
		// Apply the impact on the control side instantly, but buffer the remote side!
		Response.ApplyImpact(BulletShootDirection, PlayerOwner, Hit, BulletDamageMultiplier);

		int Index = NetBufferedImpacts.FindIndex(FIslandRedBlueBufferedImpactData(Response));
		if(Index < 0)
		{
			FIslandRedBlueBufferedImpactData Data;
			Data.ResponseComp = Response;
			Data.BulletShootDirection = BulletShootDirection;
			Data.Hit = Hit;
			Data.Damage = BulletDamageMultiplier;
			NetBufferedImpacts.Add(Data);
		}
		else
		{
			FIslandRedBlueBufferedImpactData& Data = NetBufferedImpacts[Index];
			Data.ResponseComp = Response;
			Data.BulletShootDirection = BulletShootDirection;
			Data.Hit = Hit;
			Data.Damage += BulletDamageMultiplier;
		}
		
		SetComponentTickEnabled(true);
	}

	/* Returns true if we can apply impact now, false if the impact should be buffered until a bit later (to limit the amount of RPCs per second) */
	bool CanApplyImpactNow()
	{
		if(!Network::IsGameNetworked())
			return true;

		if(Time::GetGameTimeSince(TimeOfLastBulletImpact) > (1.0 / NetMaxImpactsPerSecond))
			return true;

		return false;
	}
}

UFUNCTION()
mixin void IslandSetCurrentWeaponUpgradeType(AHazePlayerCharacter Player, EIslandRedBlueWeaponUpgradeType NewUpgradeType)
{
	auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
	WeaponUserComp.CurrentUpgradeType = NewUpgradeType;
}

UFUNCTION(BlueprintPure)
mixin EIslandRedBlueWeaponUpgradeType IslandGetCurrentWeaponUpgradeType(AHazePlayerCharacter Player)
{
	auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
	return WeaponUserComp.CurrentUpgradeType;
}

UFUNCTION(BlueprintPure)
mixin TArray<AIslandRedBlueWeapon> IslandGetPlayerWeapons(AHazePlayerCharacter Player)
{
	TArray<AIslandRedBlueWeapon> Weapons;
	auto WeaponUserComp = UIslandRedBlueWeaponUserComponent::Get(Player);
	Weapons.Add(WeaponUserComp.LeftWeapon);
	Weapons.Add(WeaponUserComp.RightWeapon);	

	return Weapons;
}