

/*
 *	This Component holds the Play/ViewMode/custom state for the player for the purposes of movement camera states such as:
 * 	- Should we activate camera settings / shakes / Impulses
 * 	- PoI´s
 * 	- General camera behavior
 */

class UPlayerMovementPerspectiveModeComponent : UActorComponent
{
	protected TInstigated<EPlayerMovementPerspectiveMode> MovementPerspectiveMode;
	default MovementPerspectiveMode.SetDefaultValue(EPlayerMovementPerspectiveMode::ThirdPerson);

	EPlayerMovementPerspectiveMode GetPerspectiveMode() const property
	{
		return MovementPerspectiveMode.Get();
	}

	bool IsCameraBehaviorEnabled() const
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		if (Player.IsCapabilityTagBlocked(n"MovementCameraBehavior"))
			return false;
		if (SceneView::IsFullScreen())
			return false;

		switch (MovementPerspectiveMode.Get())
		{
			case EPlayerMovementPerspectiveMode::ThirdPerson:
				return true;
			case EPlayerMovementPerspectiveMode::SideScroller:
			case EPlayerMovementPerspectiveMode::TopDown:
			case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
				return false;
		}
	}

	bool IsIn3DPerspective() const
	{
		switch (MovementPerspectiveMode.Get())
		{
			case EPlayerMovementPerspectiveMode::ThirdPerson:
				return true;
			case EPlayerMovementPerspectiveMode::SideScroller:
				return false;
			case EPlayerMovementPerspectiveMode::TopDown:
				return false;
			case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
				return true;
		}
	}

	bool IsIn2DPerspective() const
	{
		switch (MovementPerspectiveMode.Get())
		{
			case EPlayerMovementPerspectiveMode::ThirdPerson:
				return false;
			case EPlayerMovementPerspectiveMode::SideScroller:
				return true;
			case EPlayerMovementPerspectiveMode::TopDown:
				return true;
			case EPlayerMovementPerspectiveMode::MovingTowardsCamera:
				return false;
		}
	}

	void ApplyPerspectiveMode(EPlayerMovementPerspectiveMode Mode, FInstigator Instigator)
	{
		MovementPerspectiveMode.Apply(Mode, Instigator);
	}

	void ClearPerspectiveMode(FInstigator Instigator)
	{
		MovementPerspectiveMode.Clear(Instigator);
	}
};

enum EPlayerMovementPerspectiveMode
{
	ThirdPerson,
	SideScroller,
	TopDown,
	MovingTowardsCamera,
}