// This accessibility option allows for simply holding Jump, and a Jump, AirJump and AirDash will be performed automatically.
// The jumps are timed to get optimal distance, not height.

class UAccessibilityAutoJumpDashComponent : UActorComponent
{
	EAccessibilityAutoJumpState State;
	private UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp = UPlayerMovementComponent::Get(Owner);

#if TEST
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		if(Player != nullptr)
		{
			FHazeDevInputInfo ToggleAutoJumpDash;
			ToggleAutoJumpDash.Name = n"Toggle Auto Designer Jump";
			ToggleAutoJumpDash.Category = n"Movement";
			ToggleAutoJumpDash.DisplaySortOrder = 220;
			ToggleAutoJumpDash.AddAction(ActionNames::MovementJump);
			ToggleAutoJumpDash.OnTriggered.BindUFunction(this, n"ToggleAutoJumpDash");
			ToggleAutoJumpDash.OnStatus.BindUFunction(this, n"OnAutoJumpDashStatus");
			Player.RegisterDevInput(ToggleAutoJumpDash);
		}
#endif
	}

	UFUNCTION()
	private void ToggleAutoJumpDash()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		if(Player == Game::Mio)
		{
			int NewValue = IsEnabled() ? 0 : 1;
			Console::SetConsoleVariableInt("Haze.Accessibility.AutoJumpDash_Mio", NewValue);
		}
		else
		{
			int NewValue = IsEnabled() ? 0 : 1;
			Console::SetConsoleVariableInt("Haze.Accessibility.AutoJumpDash_Zoe", NewValue);
		}
	}

	bool IsEnabled() const
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);

		if(Player == Game::Mio)
		{
			return Accessibility::AutoJumpDash::CVar_AutoJumpDash_Mio.Int == 1;
		}
		else
		{
			return Accessibility::AutoJumpDash::CVar_AutoJumpDash_Zoe.Int == 1;
		}
	}

	UFUNCTION()
	private void OnAutoJumpDashStatus(FString& OutDescription, FLinearColor& OutColor)
	{
		if (IsEnabled())
		{
			OutDescription = "[ ON ]";
			OutColor = FLinearColor::Green;
		}
		else
		{
			OutDescription = "[ OFF ]";
			OutColor = FLinearColor::Red;
		}
	}

	bool IsAutoJumpDashing() const
	{
		return State != EAccessibilityAutoJumpState::None;
	}

	bool HasMovementInput() const
	{
		return !MoveComp.MovementInput.IsNearlyZero();
	}

	bool IsFallingDown() const
	{
		return MoveComp.VerticalVelocity.DotProduct(MoveComp.WorldUp) < 0;
	}
}

enum EAccessibilityAutoJumpState
{
	None,
	HasJumped,
	AllowAirJump,
	AllowAirDash
}

class UAccessibilityAutoJumpDashCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	UAccessibilityAutoJumpDashComponent AutoJumpDashComp;
	UPlayerMovementComponent MoveComp;
	UPlayerJumpComponent JumpComp;
	UPlayerAirJumpComponent AirJumpComp;

	float StateChangeTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AutoJumpDashComp = UAccessibilityAutoJumpDashComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		JumpComp = UPlayerJumpComponent::Get(Player);
		AirJumpComp = UPlayerAirJumpComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Player == Game::Mio)
		{
			if(Accessibility::AutoJumpDash::CVar_AutoJumpDash_Mio.Int != 1)
				return false;
		}
		else
		{
			if(Accessibility::AutoJumpDash::CVar_AutoJumpDash_Zoe.Int != 1)
				return false;
		}

		if(!JumpComp.StartedJumpingWithinDuration(0.05))
			return false;

		if(!IsActioning(ActionNames::MovementJump))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::MovementJump))
			return true;

		if(!MoveComp.IsInAir())
			return true;

		if(AutoJumpDashComp.State == EAccessibilityAutoJumpState::None)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SetState(EAccessibilityAutoJumpState::HasJumped);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AutoJumpDashComp.State = EAccessibilityAutoJumpState::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		switch(AutoJumpDashComp.State)
		{
			case EAccessibilityAutoJumpState::None:
				break;

			case EAccessibilityAutoJumpState::HasJumped:
			{
				if(Time::GetGameTimeSince(StateChangeTime) > 0.5)
					SetState(EAccessibilityAutoJumpState::AllowAirJump);

				break;
			}

			case EAccessibilityAutoJumpState::AllowAirJump:
			{
				if(AirJumpComp.bCanAirJump)
					return;

				if(Time::GetGameTimeSince(StateChangeTime) > 0.6)
					SetState(EAccessibilityAutoJumpState::AllowAirDash);
					
				break;
			}

			case EAccessibilityAutoJumpState::AllowAirDash:
				break;
		}
	}

	void SetState(EAccessibilityAutoJumpState InState)
	{
		AutoJumpDashComp.State = InState;
		StateChangeTime = Time::GameTimeSeconds;
	}
}

namespace Accessibility
{
	namespace AutoJumpDash
	{
		const FConsoleVariable CVar_AutoJumpDash_Mio("Haze.Accessibility.AutoJumpDash_Mio", 0);
		const FConsoleVariable CVar_AutoJumpDash_Zoe("Haze.Accessibility.AutoJumpDash_Zoe", 0);

		bool ShouldAutoAirJump(const AHazePlayerCharacter Player)
		{
			UAccessibilityAutoJumpDashComponent AutoJumpDashComp = UAccessibilityAutoJumpDashComponent::Get(Player);
			if(AutoJumpDashComp == nullptr)
				return false;

			if(AutoJumpDashComp.State != EAccessibilityAutoJumpState::AllowAirJump)
				return false;

			if(!AutoJumpDashComp.IsFallingDown())
				return false;

			return true;
		}

		bool ShouldAutoAirDash(const AHazePlayerCharacter Player)
		{
			UAccessibilityAutoJumpDashComponent AutoJumpDashComp = UAccessibilityAutoJumpDashComponent::Get(Player);
			if(AutoJumpDashComp == nullptr)
				return false;

			if(AutoJumpDashComp.State != EAccessibilityAutoJumpState::AllowAirDash)
				return false;

			if(!AutoJumpDashComp.HasMovementInput())
				return false;

			if(!AutoJumpDashComp.IsFallingDown())
				return false;

			return true;
		}

		void StopAutoAirJumpDash(const AHazePlayerCharacter Player)
		{
			UAccessibilityAutoJumpDashComponent AutoJumpDashComp = UAccessibilityAutoJumpDashComponent::Get(Player);
			if(AutoJumpDashComp != nullptr)
				AutoJumpDashComp.State = EAccessibilityAutoJumpState::None;
		}
	}
}