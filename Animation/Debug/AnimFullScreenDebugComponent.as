class UAnimFullScreenDebugComponent : UActorComponent
{

	AHazePlayerCharacter Player;
	private EHazeViewPointSize CurrentFullScreenMode = EHazeViewPointSize::Normal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
	}

	void SetFullScreenMode(EHazeViewPointSize NewState, EHazeViewPointBlendSpeed BlendSpeed = EHazeViewPointBlendSpeed::Instant) 
	{
		Player.ApplyViewSizeOverride(this, NewState, BlendSpeed, EHazeViewPointPriority::EHazeViewPointPriority_MAX);
		CurrentFullScreenMode = NewState;
	}

	EHazeViewPointSize GetCurrentViewSizeOverrideState() 
	{
		return CurrentFullScreenMode;
	}

	void ClearViewSizeOverride(EHazeViewPointBlendSpeed BlendSpeed = EHazeViewPointBlendSpeed::Instant)
	{
		Player.ClearViewSizeOverride(this, BlendSpeed);
		CurrentFullScreenMode = EHazeViewPointSize::Normal;
	}

	void ToggleDebugViewSizeMode()
	{
		EHazeViewPointSize NewState = EHazeViewPointSize::Normal;
		switch (CurrentFullScreenMode)
		{
			case EHazeViewPointSize::Normal:
				NewState = EHazeViewPointSize::Large;
				break;
			case EHazeViewPointSize::Large:
				NewState = EHazeViewPointSize::Fullscreen;
				break;
			default:
				break;
		}

		SetFullScreenMode(NewState);
	}


	
};