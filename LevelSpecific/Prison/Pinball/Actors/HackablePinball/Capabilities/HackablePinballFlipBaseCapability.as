struct FHackablePinballFlipBaseActivateParams
{
	float Intensity;
};

struct FHackablePinballFlipInputSample
{
	float Value = -1;
	float Time = -1;
	uint Frame;

	FHackablePinballFlipInputSample(float InValue)
	{
		Value = InValue;
		Time = Time::GameTimeSeconds;
		Frame = Time::FrameNumber;
	}
};

UCLASS(Abstract)
class UHackablePinballFlipBaseCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(Pinball::Tags::Pinball);
	
	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	AHackablePinball Flipper;
	bool bLeft = false;

	TArray<FHackablePinballFlipInputSample> InputSamples;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Drone::GetSwarmDronePlayer();
		Flipper = Cast<AHackablePinball>(Owner);

		InputSamples.Add(FHackablePinballFlipInputSample(0));
		InputSamples.Add(FHackablePinballFlipInputSample(0));
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHackablePinballFlipBaseActivateParams& Params) const
	{
		if (!Flipper.HijackableTarget.IsHijacked())
			return false;

		if(!IsActioning(GetAction()))
			return false;

		float PreviousValue = InputSamples[1].Value;
		float PreviousValueTime = InputSamples[1].Time;

		if(PreviousValueTime > 0)
		{
			const float CurrentValue = GetAttributeFloat(GetAttribute());
			const float Velocity = (CurrentValue - PreviousValue) / (Time::GameTimeSeconds - PreviousValueTime);
			Params.Intensity = Math::GetPercentageBetweenClamped(0, 10, Velocity);
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{	
		if (!Flipper.HijackableTarget.IsHijacked())
			return true;

		if(!IsActioning(GetAction()))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHackablePinballFlipBaseActivateParams Params)
	{
		if(Network::IsGameNetworked())
			check(NetworkMode == EHazeCapabilityNetworkMode::ImmediateNetFunction, "We are playing in networked with a local Flip capability!");
		
		Pinball::GetManager().StartHolding(bLeft, Params.Intensity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Pinball::GetManager().StopHolding(bLeft);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		InputSamples[1] = InputSamples[0];
		InputSamples[0] = FHackablePinballFlipInputSample(GetAttributeFloat(GetAttribute()));
	}

	FName GetAction() const
	{
		if(bLeft)
			return GetLeftAction();
		else
			return GetRightAction();
	}

	FName GetLeftAction() const
	{
		if(Player.IsUsingGamepad())
			return ActionNames::SecondaryLevelAbility;
		else
			return ActionNames::PrimaryLevelAbility;
	}

	FName GetRightAction() const
	{
		if(Player.IsUsingGamepad())
			return ActionNames::PrimaryLevelAbility;
		else
			return ActionNames::SecondaryLevelAbility;
	}

	FName GetAttribute() const
	{
		if(bLeft)
			return GetLeftAttribute();
		else
			return GetRightAttribute();
	}

	FName GetLeftAttribute() const
	{
		if(Player.IsUsingGamepad())
			return AttributeNames::PrimaryLevelAbilityAxis;
		else
			return AttributeNames::SecondaryLevelAbilityAxis;
	}

	FName GetRightAttribute() const
	{
		if(Player.IsUsingGamepad())
			return AttributeNames::PrimaryLevelAbilityAxis;
		else
			return AttributeNames::SecondaryLevelAbilityAxis;
	}
};