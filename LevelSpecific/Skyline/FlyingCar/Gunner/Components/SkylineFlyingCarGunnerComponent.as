UCLASS(Abstract)
class USkylineFlyingCarGunnerComponent : UActorComponent
{
	ASkylineFlyingCar Car;
	ASkylineFlyingCarGun Gun;
	bool bIsInAimDown = false;

	UPROPERTY(Category = "Widgets")
	FFlyingCarGunnerRifleWidgetData RifleWidgetData;

	UPROPERTY(Category = "Widgets")
	FFlyingCarGunnerBazookaWidgetData BazookaWidgetData;

	UPROPERTY()
	ECollisionChannel TraceChannel;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset AimdownSettings;

	UPROPERTY()
	UHazeCameraSettingsDataAsset BazookaAimdownSettings;

	UPROPERTY(Category = "Weapons")
	FFlyingCarGunnerRifleData RifleData;

	UPROPERTY(Category = "Weapons")
	FFlyingCarGunnerBazookaData BazookaData;

	UPROPERTY(Category = "Animations")
	UAnimSequence SitSequence;

	UPROPERTY(Transient, NotEditable)
	AFlyingCarGunnerRifle Rifle;

	UPROPERTY(Transient, NotEditable)
	AFlyingCarGunnerBazooka Bazooka;

	UPROPERTY(Transient, NotEditable)
	UStaticMeshComponent FakeRifleMeshComponent;

	UPROPERTY(Transient, NotEditable)
	UStaticMeshComponent FakeBazookaMeshComponent;


	UPROPERTY()
	FFlyingCarGunnerReloadEvent OnReloading;

	UPROPERTY()
	FFlyingCarGunnerReloadEvent OnReloaded;

	access RifleCapability = private, UFlyingCarGunnerRifleShootCapability;
	access : RifleCapability float RifleClipFraction;
	access : RifleCapability bool bReloadingRifle;

	access RifleHitMarkerCapability = private, USkylineFlyineCarRifleHitMarkerCapability, AddHitMarker;
	UPROPERTY(NotEditable, BlueprintHidden)
	access : RifleHitMarkerCapability TArray<UFlyingCarRifleHitMarkerWidget> ActiveRifleHitMarkers;

	access BazookaCapability = private, USkylineFlyingCarGunnerBazookaShootCapability;
	access : BazookaCapability bool bReloadingBazooka;

	AHazePlayerCharacter PlayerOwner;

	private EFlyingCarGunnerState GunnerState = EFlyingCarGunnerState::Rifle;

	private float AimSpaceX;
	private float AimSpaceY;

	access Shooting = private, UFlyingCarGunnerRifleShootCapability, USkylineFlyingCarGunnerBazookaShootCapability;
	access : Shooting bool bShooting;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void SetupWeapons()
	{
		// Create weapons and attach'em to player mesh
		Rifle = SpawnActor(RifleData.RifleClass);
		Rifle.AttachToComponent(PlayerOwner.Mesh, n"RightAttach");
		Rifle.SetActorHiddenInGame(true);

		Bazooka = SpawnActor(BazookaData.BazookaClass);
		Bazooka.AttachToComponent(PlayerOwner.Mesh, n"RightAttach");
		Bazooka.SetActorHiddenInGame(true);

		// Setup fake weapons
		FakeRifleMeshComponent = UStaticMeshComponent::GetOrCreate(Car, n"FlyingCar_Mio_FakeRifle");
		FakeRifleMeshComponent.AttachToComponent(Car.FakeMio, n"RightAttach");
		FakeRifleMeshComponent.SetStaticMesh(Rifle.Mesh.StaticMesh);
		FakeRifleMeshComponent.SetHiddenInGame(true);

		FakeBazookaMeshComponent = UStaticMeshComponent::GetOrCreate(Car, n"FlyingCar_Mio_FakeBazooka");
		FakeBazookaMeshComponent.AttachToComponent(Car.FakeMio, n"RightAttach");
		FakeBazookaMeshComponent.SetStaticMesh(Bazooka.Mesh.StaticMesh);
		FakeBazookaMeshComponent.SetHiddenInGame(true);

		// Don't render fake weapones for this gunner
		FakeRifleMeshComponent.SetRenderedForPlayer(PlayerOwner, false);
		FakeBazookaMeshComponent.SetRenderedForPlayer(PlayerOwner, false);

		// Don't render legit weapons for pilot
		Rifle.Mesh.SetRenderedForPlayer(PlayerOwner.OtherPlayer, false);
		Bazooka.Mesh.SetRenderedForPlayer(PlayerOwner.OtherPlayer, false);
	}

	void UpdateBlendSpaceValues()
	{
		float ClampedCameraPitch = Math::Max(-60, PlayerOwner.ActorTransform.InverseTransformRotation(PlayerOwner.ControlRotation).Pitch);

		AimSpaceY = ClampedCameraPitch;

		FRotator LocalRotation = (Car.ActorQuat.Inverse() * PlayerOwner.ViewRotation.Quaternion()).Rotator();
		AimSpaceX = LocalRotation.Yaw;
	}

	UFUNCTION()
	void PopIn()
	{
		SetGunnerState(EFlyingCarGunnerState::Seating);
	}

	UFUNCTION()
	void PopOut(EFlyingCarGunnerState NewGunnerState)
	{
		SetGunnerState(NewGunnerState);
	}

	UFUNCTION()
	void SetGunnerState(EFlyingCarGunnerState NewGunnerState)
	{
		GunnerState = NewGunnerState;
	}

	UFUNCTION(BlueprintPure)
	EFlyingCarGunnerState GetGunnerState() const
	{
		return GunnerState;
	}

	// Returns value between 0 and 1
	UFUNCTION(BlueprintPure)
	float GetRifleClipFraction() const
	{
		return RifleClipFraction;
	}

	UFUNCTION(BlueprintPure)
	UStaticMeshComponent GetRifleMeshComponent() const
	{
		if (Rifle == nullptr)
			return nullptr;

		return Rifle.Mesh;
	}

	UFUNCTION(BlueprintPure)
	bool IsReloadingRifle() const
	{
		return bReloadingRifle;
	}

	UFUNCTION(BlueprintPure)
	bool IsReloadingBazooka() const
	{
		return bReloadingBazooka;
	}

	UFUNCTION(BlueprintPure)
	bool IsSittingInsideCar() const
	{
		return GunnerState == EFlyingCarGunnerState::Seating;
	}

	// Can be either rifle or bazooka (the latter will be active for 1 frame only)
	UFUNCTION(BlueprintPure)
	bool IsShooting() const
	{
		return bShooting;
	}

	void GetAimSpaceData(float& X, float& Y) const
	{
		X = AimSpaceX;
		Y = AimSpaceY;
	}
}
