class USkylinePhoneUserComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylinePhoneWielder> PhoneWielderClass;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylinePhoneBase> PhoneClass;

	ASkylinePhoneWielder PhoneWielder;
	ASkylinePhoneBase Phone;

	UPROPERTY(EditDefaultsOnly)
	FTransform PhoneRelativeTransform;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraViewPointBlendType BlendInType;

	AHazePlayerCharacter Player;

	float CursorSpeed = 1000.0;
	const float CursorAccelerationDuration = 0.0;
	FVector2D Input;
	bool bClickPressed = false;

	bool bUsePhoneView = false;
	bool bSnapPhoneView = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	ASkylinePhoneBase SpawnPhone()
	{
		Phone = SpawnActor(PhoneClass, bDeferredSpawn = true);
		Phone.MakeNetworked(this, 0);
		FinishSpawningActor(Phone);
		Phone.SetActorControlSide(Player);
		return Phone;
	}

	void SetupPhone()
	{
		if(Phone == nullptr)
			SpawnPhone();
		
		if(Cast<ASkylinePhone>(Phone) != nullptr)
		{
			CursorSpeed = 400;
		}

		bool bUseWielder = true;

		if(bUseWielder)
		{
			PhoneWielder = SpawnActor(PhoneWielderClass);
			PhoneWielder.Phone = Phone;
			PhoneWielder.AttachToActor(Player, n"RightShoulder");
			PhoneWielder.ActorRelativeTransform = PhoneRelativeTransform;
		}

		Phone.AttachToActor(Player, n"RightAttach");
		Player.BlockCapabilities(n"CameraHideOverlappers", this);
		Game::Mio.Mesh.SetRenderedForPlayer(Player, false);
		Phone.bGameStarted = true;
	}

	void RemovePhone()
	{
		Player.UnblockCapabilities(n"CameraHideOverlappers", this);
		PhoneWielder.DestroyActor();
		bUsePhoneView = false;
		Game::Mio.Mesh.SetRenderedForPlayer(Player, true);
	}

	void ActivatePhoneMode()
	{
		Player.ApplyViewSizeOverride(
			this,
			EHazeViewPointSize::Small,
			EHazeViewPointBlendSpeed::Instant,
			EHazeViewPointPriority::High
		);

		Player.OtherPlayer.ApplyViewSizeOverride(
			this,
			EHazeViewPointSize::Large,
			EHazeViewPointBlendSpeed::Instant,
			EHazeViewPointPriority::High
		);

		float CameraBlendTime = bSnapPhoneView ? 0.0 : 1.0;
		Player.ActivateCameraCustomBlend(PhoneWielder.Camera, BlendInType, CameraBlendTime, this, EHazeCameraPriority::High);

		PhoneWielder.StartFocusActionQueue(CameraBlendTime);
	
		Phone.SetActorTickEnabled(true);
	}

	void DeactivatePhoneMode()
	{
		Player.DeactivateCameraByInstigator(this);
		Player.ClearViewSizeOverride(this);
		Player.OtherPlayer.ClearViewSizeOverride(this);

		Phone.SetActorTickEnabled(false);
	}

	void PhoneCompleted()
	{
		Phone.bPhoneCompleted = true;
		Timer::SetTimer(this, n"ClearPhoneView", 1.0);
	}

	UFUNCTION()
	private void ClearPhoneView()
	{
		Player.ClearViewSizeOverride(this);
		Player.OtherPlayer.ClearViewSizeOverride(this);
	}

	UFUNCTION(DevFunction)
	void DevActivatePhone()
	{
		bUsePhoneView = true;
	}

	void SavePhoneGameProgress()
	{
		if(Phone == nullptr)
			return;

		if(!Phone.bProgressMadeSinceLastLoad)
			return;
		
		Save::ModifyPersistentProfileCounter(n"PhoneGameProgress", Phone.PhoneGameIndex - 1);
	}

	void ResetPhoneGameProgress()
	{
		Save::ModifyPersistentProfileCounter(n"PhoneGameProgress", -1);
	}

	UFUNCTION(BlueprintPure)
	int GetCurrentPhoneGameByIndex()
	{
		return Phone.PhoneGameIndex;
	}
};