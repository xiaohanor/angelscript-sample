event void FOnBeforeCentipedeBiteStopped(FCentipedeBiteEventParams BiteParams);

class USanctuaryLavamoleCentipedeBiteResponseComponent : UCentipedeBiteResponseComponent
{
	AHazePlayerCharacter Biter = nullptr;
	FCentipedeBiteEventParams BiterParams;
	UHazeActionQueueComponent ActionComp;
	FOnBeforeCentipedeBiteStopped OnBeforeCentipedeBiteStopped;
	AAISanctuaryLavamole Mole;

	private FString DebugBitingName = "Mole Bite Response";

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		Mole = Cast<AAISanctuaryLavamole>(Owner);

		OnCentipedeBiteStarted.AddUFunction(this, n"OnMoleBiteStarted");
		OnCentipedeBiteStopped.AddUFunction(this, n"OnMoleBiteStopped");

		Mole.OnMoleStartedDying.AddUFunction(this, n"OnMoleDied");

		ActionComp = UHazeActionQueueComponent::GetOrCreate(Owner);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if (Mole.bIsUnderground)
			return false;
		if (Biter != nullptr)
			return false;
		if (Mole.bIsWhacky)
			return false;
		if (Mole.WhackedTimes > Mole.WhackTimesDeath)
			return false;
		if (!IsValid(Mole))
			return false;
		bool Targetable = Super::CheckTargetable(Query);
		//Debug::DrawDebugString(WorldLocation, "Enabled? " + GetName() + Targetable);
		return Targetable;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMoleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		if (!IsValid(Mole))
			return;
		Biter = BiteParams.Player;
		BiterParams = BiteParams;
		DisableForPlayer(BiteParams.Player.OtherPlayer, this);
		BiteParams.CentipedeBiteComponent.ApplyDoubleInteractionBite(this);
		if (SanctuaryCentipedeDevToggles::Mole::TearCoopMoles.IsEnabled())
			ActionComp.Empty();
		else
			WhackaMole();
	}

	void WhackaMole() // this should be networked due to centipede bite being networked
	{
		if (!Mole.HasControl())
			return;

		if (Mole.WhackedTimes < Mole.WhackTimesDeath)
		{
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionWhackedCapability, FSanctuaryLavamoleActionWhackedData());
				ActionComp.Capability(USanctuaryLavamoleActionDigDownCapability, FSanctuaryLavamoleActionDigDownData());
				ActionComp.SetLooping(false);
			}
		}
		else if (Mole.WhackedTimes == Mole.WhackTimesDeath)
		{
			{
				ActionComp.Empty();
				ActionComp.Capability(USanctuaryLavamoleActionSplitCapability, FSanctuaryLavamoleActionSplitData());
				ActionComp.SetLooping(false);
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMoleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		OnBeforeCentipedeBiteStopped.Broadcast(BiteParams);

		if (BiteParams.CentipedeBiteComponent != nullptr)
			BiteParams.CentipedeBiteComponent.ClearDoubleInteractionBite(this);

		if (BiteParams.Player != nullptr)
			EnableForPlayer(BiteParams.Player.OtherPlayer, this);

		BiterParams = FCentipedeBiteEventParams();
		Biter = nullptr;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnMoleDied(AAISanctuaryLavamole MoleOwner)
	{
		if (Biter != nullptr)
		{
			FCentipedeBiteEventParams BiteParams;
			BiteParams.Player = Biter;
			BiteParams.CentipedeBiteComponent = UCentipedeBiteComponent::Get(Biter);
			OnBeforeCentipedeBiteStopped.Broadcast(BiteParams);

			BiteParams.CentipedeBiteComponent.ClearDoubleInteractionBite(this);

			Biter = nullptr;
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		// if (Biter != nullptr)
		// 	Debug::DrawDebugString(WorldLocation, "Bitten!");
		FString Category = GetName() + "";
		auto TemporalLog = TEMPORAL_LOG(Owner, DebugBitingName);
		// FLinearColor BiteyColor = this.IsDisabled() ? ColorDebug::Ruby : ColorDebug::Leaf;
		// TemporalLog.Sphere("?", WorldLocation, PlayerRange, BiteyColor);
		TemporalLog.Value(Category + " Biter:", Biter);
		TemporalLog.Value(Category + " Enabled:", !this.IsDisabled());
	}
#endif
}