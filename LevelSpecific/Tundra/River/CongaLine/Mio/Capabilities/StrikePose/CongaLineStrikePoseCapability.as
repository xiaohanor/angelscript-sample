asset CongaLineStrikePosePlayerSettings of UCongaLinePlayerSettings
{
	MoveSpeed = CongaLine::DefaultMoveSpeed - 100;
	InterpTowardsDirectionTurnSpeed = 1.5;
};

/**
 * This capability is active when we play a pose animation
 * It also slows down the player.
 */
class UCongaLineStrikePoseCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CongaLine::Tags::CongaLine);
	default CapabilityTags.Add(CongaLine::Tags::CongaLineStrikePose);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	ACongaLineManager Manager;
	UCongaLinePlayerComponent CongaComp;
	UCongaLineStrikePoseComponent StrikePoseComp;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData MoveData;

	int CurrentMeasure;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = CongaLine::GetManager();
		CongaComp = UCongaLinePlayerComponent::Get(Player);
		StrikePoseComp = UCongaLineStrikePoseComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSteppingMovementData();


	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!StrikePoseComp.ShouldStrikePose())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > CongaLine::StrikePoseDuration)
			return true;

		if(CurrentMeasure < Manager.GetCurrentMeasure())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentMeasure = CongaLine::GetManager().GetCurrentMeasure();

		// Promote the pose we were supposed to input to be the pose we should strike
		StrikePoseComp.bIsPosing = true;

		//Player.ApplySettings(CongaLineStrikePosePlayerSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		StrikePoseComp.bIsPosing = false;

		//Player.ClearSettingsByInstigator(this);
	}


};