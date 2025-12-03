struct FMagnetDroneAttractionModeSetupParams
{
	AHazePlayerCharacter Player;

	FMagnetDroneAttractionModeSetupParams(
		AHazePlayerCharacter InPlayer
	)
	{
		Player = InPlayer;
	}
};

struct FMagnetDroneAttractionModeShouldActivateParams
{
	FVector PlayerLocation;
	FVector PlayerVelocity;
	bool bIsAttached;
	FMagnetDroneTargetData AimData;
	EMagnetDroneStartAttractionInstigator Instigator;
	bool bIsPreview;

	FMagnetDroneAttractionModeShouldActivateParams(
		FVector InPlayerLocation,
		FVector InPlayerVelocity,
		bool bInIsAttached,
		FMagnetDroneTargetData InAimData,
		EMagnetDroneStartAttractionInstigator InInstigator,
		bool bInIsPreview
	)
	{
		PlayerLocation = InPlayerLocation;
		PlayerVelocity = InPlayerVelocity;
		bIsAttached = bInIsAttached;
		AimData = InAimData;
		Instigator = InInstigator;
		bIsPreview = bInIsPreview;
	}
};

struct FMagnetDroneAttractionModePrepareAttractionParams
{
	const UMagnetDroneAttractionSettings AttractionSettings;
	const FMagnetDroneTargetData AttractionTarget;

	FVector InitialLocation;
	FVector InitialVelocity;
	const FVector InitialWorldUp;
	const FRotator InitialViewRotation;
	const float InitialGameTime;
	const EPlayerTargetingMode TargetingMode;

	/**
	 * Construct with just values, used for previews
	 */
	FMagnetDroneAttractionModePrepareAttractionParams(
		const UMagnetDroneAttractionSettings InAttractionSettings,
		FMagnetDroneTargetData InAttractionTarget,
		FVector InInitialLocation,
		FVector InInitialVelocity,
		FVector InInitialWorldUp,
		FRotator InInitialViewRotation,
		float InInitialGameTime,
	)
	{
		AttractionSettings = InAttractionSettings;
		AttractionTarget = InAttractionTarget;

		InitialLocation = InInitialLocation;
		InitialVelocity = InInitialVelocity;
		InitialWorldUp = InInitialWorldUp;
		InitialViewRotation = InInitialViewRotation;
		InitialGameTime = InInitialGameTime;
	}

	/**
	 * Construct with a player, used with the attraction capabilities
	 */
	FMagnetDroneAttractionModePrepareAttractionParams(
		AHazePlayerCharacter InPlayer,
		FMagnetDroneTargetData InAttractionTarget,
	)
	{
		AttractionSettings = UMagnetDroneAttractionSettings::GetSettings(InPlayer);
		AttractionTarget = InAttractionTarget;

		InitialLocation = InPlayer.ActorLocation;
		InitialVelocity = InPlayer.ActorVelocity;

		InitialWorldUp = InPlayer.MovementWorldUp;
		InitialViewRotation = InPlayer.ViewRotation;
		InitialGameTime = Time::GameTimeSeconds;

		auto TargetablesComp = UPlayerTargetablesComponent::Get(InPlayer);
		if(TargetablesComp != nullptr)
			TargetingMode = TargetablesComp.TargetingMode.Get();
		else
			TargetingMode = EPlayerTargetingMode::ThirdPerson;
	}

	/**
	 * Construct with a Proxy and Control Player
	 * Used in Pinball Prediction
	 */
	FMagnetDroneAttractionModePrepareAttractionParams(
		APinballMagnetDroneProxy InProxy,
		AHazePlayerCharacter InControlPlayer,
		FMagnetDroneTargetData InAttractionTarget,
	)
	{
		AttractionSettings = UMagnetDroneAttractionSettings::GetSettings(InControlPlayer);
		AttractionTarget = InAttractionTarget;

		InitialLocation = InProxy.ActorLocation;
		InitialVelocity = InProxy.ActorVelocity;

		InitialWorldUp = InProxy.MovementWorldUp;
		InitialViewRotation = InControlPlayer.ViewRotation;
		InitialGameTime = Time::GameTimeSeconds;

		auto TargetablesComp = UPlayerTargetablesComponent::Get(InControlPlayer);
		if(TargetablesComp != nullptr)
			TargetingMode = TargetablesComp.TargetingMode.Get();
		else
			TargetingMode = EPlayerTargetingMode::ThirdPerson;
	}

	void ApplyOnPreview(
		FVector& InInitialLocation,
		FVector& InInitialVelocity,
	) const
	{
		if(!InInitialLocation.Equals(InitialLocation))
			InInitialLocation = InitialLocation;
		
		if(!InInitialVelocity.Equals(InitialVelocity))
			InInitialVelocity = InitialVelocity;
	}

	void ApplyOnPlayer(AHazePlayerCharacter InPlayer) const
	{
		if(!InPlayer.ActorLocation.Equals(InitialLocation))
			InPlayer.SetActorLocation(InitialLocation);

		if(!InPlayer.ActorVelocity.Equals(InitialVelocity))
			InPlayer.SetActorVelocity(InitialVelocity);
	}

	void ApplyOnProxy(APinballMagnetDroneProxy InProxy) const
	{
		if(!InProxy.ActorLocation.Equals(InitialLocation))
			InProxy.SetActorLocation(InitialLocation);

		if(!InProxy.ActorVelocity.Equals(InitialVelocity))
			InProxy.SetActorVelocity(InitialVelocity);
	}
};

struct FMagnetDroneAttractionModeTickAttractionParams
{
	FVector CurrentLocation;
	FVector CurrentVelocity;
	float ActiveDuration;
	float CurrentGameTime;

	FMagnetDroneAttractionModeTickAttractionParams(
		FVector InCurrentLocation,
		FVector InCurrentVelocity,
		float InActiveDuration,
		float InCurrentGameTime,
	)
	{
		CurrentLocation = InCurrentLocation;
		CurrentVelocity = InCurrentVelocity;
		ActiveDuration = InActiveDuration;
		CurrentGameTime = InCurrentGameTime;
	}
};