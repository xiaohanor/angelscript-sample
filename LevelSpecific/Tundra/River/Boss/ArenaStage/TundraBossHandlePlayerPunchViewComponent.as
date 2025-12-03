/*
Handling the Mio and Zoe grab/punch camera activations and deactivations here 
because they activates in different Boss Capabilities. And Mio's 
camera need to be able to cancel Zoe's camera.
*/

class UTundraBossHandlePlayerPunchViewComponent : UActorComponent
{
	ATundraBoss Boss;
	float ZoeDeactivationTimer;
	bool bShouldTickZoeDeactivationTimer = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ATundraBoss>(Owner);
	}

	void StartZoeGrabCamera()
	{
		Game::Zoe.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
		
		//Starts the TreeGrab SEQ
		Boss.StartTreeGrabSeq.Broadcast();	
	}

	void MarkZoeGrabCameraForDeactivation(float DeactivationTime, bool bGrabSuccessful = false)
	{
		if(DeactivationTime == 0)
		{
			StopZoeGrabCamera();
		}
		else
		{
			ZoeDeactivationTimer = DeactivationTime;
			bShouldTickZoeDeactivationTimer = true;
		}

		if(bGrabSuccessful)
			ApplyZoeKeepIceKingDownCamSettings();
		else
			ClearZoeKeepIceKingDownCamSettings();
	}

	void ApplyZoeKeepIceKingDownCamSettings()
	{
		Game::Zoe.ApplyCameraSettings(Boss.ZoeKeepIceKingDownCamSettings, 2.0 ,this);
	}

	void ClearZoeKeepIceKingDownCamSettings()
	{
		Game::Zoe.ClearCameraSettingsByInstigator(this);
	}

	private void StopZoeGrabCamera()
	{
		Game::Zoe.ClearViewSizeOverride(this);
		Boss.StopTreeGrabSeq.Broadcast();
	}

	void StartMioPunchCamera(bool bIsLastPhase)
	{
		if(bShouldTickZoeDeactivationTimer)
			StopZoeGrabCamera();
		
		if(!bIsLastPhase)
		{
			Game::Mio.ActivateCamera(Boss.MonkeyPunchCamera, 1, this);
			Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
		}
		else
		{
			Game::Mio.ActivateCamera(Boss.SecondPunchCamera, 1, this);
			Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Fast);
		}
	}

	void StopMioPunchCamera(bool bIsLastPhase)
	{
		if(!bIsLastPhase)
			Game::Mio.ClearViewSizeOverride(this);
		
		Game::Mio.DeactivateCameraByInstigator(this);
		ClearZoeKeepIceKingDownCamSettings();
	}

	// Called when Fullscreen persists for a bit
	void ClearPunchCamViewSizeOverride()
	{
		Game::Mio.ClearViewSizeOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bShouldTickZoeDeactivationTimer)
		{
			ZoeDeactivationTimer -= DeltaSeconds;
			if(ZoeDeactivationTimer <= 0)
			{
				bShouldTickZoeDeactivationTimer = false;
				StopZoeGrabCamera();
			}
		}
	}
};