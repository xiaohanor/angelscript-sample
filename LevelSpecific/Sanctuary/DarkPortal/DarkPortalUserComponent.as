struct FDarkPortalAnimationData
{
	bool bIsAiming = false;
	FVector2D AimSpace = FVector2D::ZeroVector;
}

class UDarkPortalUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Portal")
	TSubclassOf<ADarkPortalActor> DarkPortalClass;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Portal")
	TSubclassOf<UCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Portal")
	UNiagaraSystem IndicatorEffect;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Portal")
	TSubclassOf<UHazeUserWidget> IndicatorWidget;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Portal")
	ADarkPortalActor Portal;

	UPROPERTY(NotVisible, BlueprintReadOnly, Category = "Portal")
	FDarkPortalAnimationData AnimationData;

	UPROPERTY(BlueprintReadOnly, Category = "Portal")
	UHazeCameraSettingsDataAsset CameraAimSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Companion")
	TSubclassOf<AAISanctuaryDarkPortalCompanion> CompanionClass;

	AAISanctuaryDarkPortalCompanion Companion = nullptr;
	bool bCompanionEnabled = false;

	FDarkPortalTargetData AimTargetData;
	AHazePlayerCharacter Player;

	bool bIsIntroducing = false;
	FVector IntroLocation;
	FRotator IntroRotation;

	bool bWantsRecall = false;
	float LastAimStartTime = 0.0;
	bool bShowAimForOtherPlayer = false;

	bool bUseBoatAimingRange = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);

		if (DarkPortalClass != nullptr)
		{
			Portal = SpawnActor(DarkPortalClass, bDeferredSpawn = true, Level = Player.Level);
			Portal.Player = Player;
			Portal.MakeNetworked(Player, n"DarkPortal");
			Portal.SetActorControlSide(Player);
			FinishSpawningActor(Portal);
			
			FTransform SocketTransform = Player.Mesh.GetSocketTransform(DarkPortal::Absorb::AttachSocket);
			Portal.AttachPortal(SocketTransform, Player.Mesh, DarkPortal::Absorb::AttachSocket);
		}

#if EDITOR
		// Don't allow dropping portal if networked, only used for testing
		//  so not worth bothering in networked
		if (!Network::IsGameNetworked())
		{
			FHazeDevInputInfo Info;
			Info.Name = n"Drop Portal";
			Info.Category = n"Default";
			Info.OnTriggered.BindUFunction(this, n"DropPortal");
			Info.AddKey(EKeys::P);
			Player.RegisterDevInput(Info);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (Portal != nullptr)
		{
			Portal.DestroyActor();
			Portal = nullptr;
		}
		if (Companion != nullptr)
		{
			Companion.DestroyActor();
			Companion = nullptr;
		}
	}

	UFUNCTION()
	void EnableCompanion(FInstigator Instigator)
	{
		if (Companion == nullptr)
			return;
		if (bCompanionEnabled)
			return;

		bCompanionEnabled = true;
		Companion.UnblockCapabilities(n"Companion", Instigator);			
		Companion.RemoveActorDisable(Instigator);
	}
	
	UFUNCTION()
	void DisableCompanion(FInstigator Instigator)
	{
		if (Companion == nullptr)
			return;
		if (!bCompanionEnabled)
			return;

		bCompanionEnabled = false;
		Companion.BlockCapabilities(n"Companion", Instigator);			
		Companion.AddActorDisable(Instigator);
	}


#if EDITOR
	private TArray<ADarkPortalActor> DroppedPortals;

	/**
	 * Drops the active portal in the world in it's current state and spawns a new one for the player.
	 * Expects the portal to be attached and grabbing something, otherwise it has no functionality :^)
	 */
	UFUNCTION()
	private void DropPortal()
	{
		if (DarkPortalClass == nullptr || !Portal.IsAttachValid() || !Portal.IsGrabbingAny() || Network::IsGameNetworked())
			return;

		DroppedPortals.Add(Portal);

		Portal = SpawnActor(DarkPortalClass, bDeferredSpawn = true);
		Portal.Player = Player;
		FinishSpawningActor(Portal);
		
		FTransform SocketTransform = Player.Mesh.GetSocketTransform(DarkPortal::Absorb::AttachSocket);
		Portal.AttachPortal(SocketTransform, Player.Mesh, DarkPortal::Absorb::AttachSocket);
	}
#endif
}