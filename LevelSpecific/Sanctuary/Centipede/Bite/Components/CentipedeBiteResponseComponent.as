class UCentipedeBiteResponseComponent : UTargetableComponent
{
	UPROPERTY(EditAnywhere, Category = "Aiming")
	float PlayerRange = 300.0;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	bool bAutoTargetWhileBitten = true;

	UPROPERTY(EditAnywhere, Category = "Aiming")
	bool bDisabledAutoTargeting = false;

	UPROPERTY(EditAnywhere, Category = "Movement")
	bool bBlocksPlayerMovement = false;

	UPROPERTY(EditAnywhere, Category = "Audio", DisplayName = "Bite Start Event")
	UHazeAudioEvent BiteStartAudioEvent;

	UPROPERTY(EditAnywhere, Category = "Audio", DisplayName = "Bite Stop Event")
	UHazeAudioEvent BiteStartStopAudioEvent;

	default TargetableCategory = n"CentipedeBite";

	UPROPERTY()
	FOnCentipedeBiteStarted OnCentipedeBiteStarted;

	UPROPERTY()
	FOnCentipedeBiteStopped OnCentipedeBiteStopped;

	protected bool bBitten = false;
	private bool bPlayerMovementBlocked = false;

	// Used to handle mutex interactions between players
	access NetworkBite = private, UCentipedeBiteActivationCapability;
	access : NetworkBite UNetworkLockComponent NetworkLockComponent;

	AHazePlayerCharacter DebugBitingPlayer;
	FLinearColor DebugColor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		uint8 Hue = uint8(Math::RandRange(100, 200));
		DebugColor = FLinearColor::MakeFromHSV8(Hue, 255, 255);
		Super::BeginPlay();

		NetworkLockComponent = UNetworkLockComponent::Create(Owner, FName(Name + "_NetworkLock"));

		OnCentipedeBiteStarted.AddUFunction(this, n"OnBiteStarted");
		OnCentipedeBiteStopped.AddUFunction(this, n"OnBiteStopped");
		SanctuaryCentipedeDevToggles::Draw::Biting.MakeVisible();
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (bBitten)
			return false;

		Targetable::ApplyVisibleRange(Query, PlayerRange * 3.0);
		Targetable::ApplyTargetableRange(Query, PlayerRange);
		//Targetable::ScoreCameraTargetingInteraction(Query); // note(Ylva) We don't want to account for camera angles with Cento, since we have all kind of whacky perspectives
		//Targetable::RequireNotOccludedFromCamera(Query);

		return Query.Result.bPossibleTarget;
	}

	FTransform GetAdjustedInteractionTransformForPlayer(AHazePlayerCharacter Player)
	{
		//Debug::DrawDebugSphere(WorldLocation);
		FVector TargetToPlayer = (WorldLocation - Player.ActorLocation).GetSafeNormal();
		//Debug::DrawDebugDirectionArrow(Player.ActorLocation, TargetToPlayer, WorldLocation.Distance(Player.ActorLocation), 5, FLinearColor::Yellow * FLinearColor::Red, 10);

		FVector Location = WorldLocation - TargetToPlayer * Centipede::PlayerMeshMandibleOffset;
		FQuat Rotation = FQuat::MakeFromXZ(TargetToPlayer, Player.MovementWorldUp);

		return FTransform(Rotation, Location);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		bBitten = true;
		DebugBitingPlayer = BiteParams.Player;

		if (bBlocksPlayerMovement)
		{
			BiteParams.Player.BlockCapabilities(CentipedeTags::CentipedeMovement, this);
			bPlayerMovementBlocked = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		bBitten = false;
		DebugBitingPlayer = nullptr;

		if (bPlayerMovementBlocked)
		{
			BiteParams.Player.UnblockCapabilities(CentipedeTags::CentipedeMovement, this);
			bPlayerMovementBlocked = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SanctuaryCentipedeDevToggles::Draw::Biting.IsEnabled())
		{
			FLinearColor Colorings = DebugColor;
			if (IsDisabledForPlayer(Game::Mio) || IsDisabledForPlayer(Game::Zoe))
				Colorings = ColorDebug::Ruby;
			if (bBitten && DebugBitingPlayer != nullptr)
				Colorings = DebugBitingPlayer.IsMio() ? ColorDebug::Yellow : ColorDebug::Purple;
			Debug::DrawDebugCircle(WorldLocation, PlayerRange, 8, Colorings);
			Debug::DrawDebugString(WorldLocation, " " + Owner.GetName(), Colorings);
		}

		// Give the closest player an advantage
		for (auto Player : Game::Players)
			NetworkLockComponent.ApplyOwnerHint(Player, this, -Player.ActorLocation.DistSquared(WorldLocation));
	}

	bool IsBitten() const
	{
		return bBitten;
	}
}

class UCentipedeBiteResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCentipedeBiteResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UCentipedeBiteResponseComponent BiteResponseComponent = Cast<UCentipedeBiteResponseComponent>(Component);
		if (BiteResponseComponent == nullptr)
			return;

		DrawCircle(BiteResponseComponent.WorldLocation, BiteResponseComponent.PlayerRange, FLinearColor::Green, 2);
		for (float Angle = 0; Angle < 360; Angle += 20)
		{
			FVector UpVector = FVector::UpVector;
			FVector Direction = BiteResponseComponent.ForwardVector.ConstrainToPlane(UpVector).GetSafeNormal().RotateAngleAxis(Angle, UpVector);
			DrawLine(BiteResponseComponent.WorldLocation, BiteResponseComponent.WorldLocation + Direction * BiteResponseComponent.PlayerRange, FLinearColor::Green * 0.5, 2);
		}
	}
} 