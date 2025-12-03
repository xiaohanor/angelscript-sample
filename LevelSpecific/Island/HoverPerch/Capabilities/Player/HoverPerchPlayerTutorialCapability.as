class UHoverPerchPlayerTutorialCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	UHoverPerchPlayerComponent HoverPerchComp;
	UHazeActionQueueComponent ActionQueueComp;
	UPlayerPerchComponent PerchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerchComp = UHoverPerchPlayerComponent::GetOrCreate(Player);
		PerchComp = UPlayerPerchComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(HoverPerch == nullptr)
			return false;

		if(!HoverPerch.bShowTutorialPrompts)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FHoverPerchPlayerTutorialDeactivatedParams& Params) const
	{
		if(HoverPerch == nullptr)
			return true;

		if(ActionQueueComp == nullptr || ActionQueueComp.IsEmpty())
		{
			Params.bTutorialCompleted = true;
			return true;
		}
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(ActionQueueComp == nullptr)
			ActionQueueComp = UHazeActionQueueComponent::GetOrCreate(Player, n"HoverPerchTutorialActionQueue");

		ActionQueueComp.Capability(UHoverPerchPlayerTutorialActionMoveCapability);
		ActionQueueComp.Capability(UHoverPerchPlayerTutorialActionJumpCapability);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FHoverPerchPlayerTutorialDeactivatedParams Params)
	{
		if(Params.bTutorialCompleted && HoverPerch != nullptr)
			HoverPerch.bShowTutorialPrompts = false;

		if(ActionQueueComp != nullptr)
		{
			ActionQueueComp.Empty();
		}
	}

	AHoverPerchActor GetHoverPerch() const property
	{
		return HoverPerchComp.PerchActor;
	}
}

struct FHoverPerchPlayerTutorialDeactivatedParams
{
	bool bTutorialCompleted = false;
}

UCLASS(Abstract)
class UHoverPerchPlayerTutorialActionBaseCapability : UHazeActionQueuePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UHoverPerchPlayerComponent HoverPerchComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HoverPerchComp = UHoverPerchPlayerComponent::GetOrCreate(Player);
	}

	AHoverPerchActor GetHoverPerch() const property
	{
		return HoverPerchComp.PerchActor;
	}
}

class UHoverPerchPlayerTutorialActionMoveCapability : UHoverPerchPlayerTutorialActionBaseCapability
{
	FTutorialPrompt MovePrompt;
	default MovePrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
	default MovePrompt.Text = NSLOCTEXT("Island", "HoverPerchMoveTutorial", "Move");

	FVector StartingLocation;

	const float Length = 1000.0;

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(StartingLocation.DistSquared(HoverPerch.ActorLocation) > Math::Square(Length))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// This can happen if both players jump on the same hover perch in network at the same time.
		if(HoverPerch == nullptr)
			return;

		StartingLocation = HoverPerch.ActorLocation;
		Player.ShowTutorialPrompt(MovePrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}

class UHoverPerchPlayerTutorialActionJumpCapability : UHoverPerchPlayerTutorialActionBaseCapability
{
	FTutorialPrompt JumpPrompt;
	default JumpPrompt.DisplayType = ETutorialPromptDisplay::Action;
	default JumpPrompt.Action = ActionNames::MovementJump;
	default JumpPrompt.Text = NSLOCTEXT("Island", "HoverPerchJumpTutorial", "Jump");

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(WasActionStarted(ActionNames::MovementJump))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ShowTutorialPrompt(JumpPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}
}