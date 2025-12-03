
/**
 * Will be used to spawn Rain/Snow/Smoke effects on the primary camera while previewing in editor, and only in editor.
 */

const FConsoleVariable CVar_VFXAmbienceFlags("HazeVFX.WeatherEffect", 0, "Cycles through different weather effects.\n 0. Turn off \n 1. Snow \n 2. Rain");

#if EDITOR

class UPreviewWeatherEffectSubsystem : UHazeEditorSubsystem
{
	UNiagaraComponent ActiveEffect;
	int PreviousConsoleValue = 0;

	UFUNCTION(BlueprintOverride)
	void Initialize()
	{
		DestroyNiagara();
	}

	UFUNCTION(BlueprintOverride)
	void Deinitialize()
	{
		DestroyNiagara();
	}

	UFUNCTION(BlueprintOverride)
	void OnEditorLevelsChanged()
	{
		DestroyNiagara();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FAngelscriptExcludeScopeFromLoopTimeout ExcludeFromTimeout;

		const int CurrentConsoleValue = CVar_VFXAmbienceFlags.GetInt();

		// Disable preview; kill all active effects
		if(CurrentConsoleValue <= 0)
		{
			DestroyNiagara();
			return;
		}

		// Kill all effects when we are playing, they won't show up anyway.
		const UWorld GPWorld = UUnrealEditorSubsystem::Get().GetGameWorld();
		if(GPWorld != nullptr)
		{
			DestroyNiagara();
			return;
		}

		// clean up and start fresh when console value changes
		if(CurrentConsoleValue != PreviousConsoleValue)
		{
			DestroyNiagara();
			PreviousConsoleValue = CurrentConsoleValue;
		}

		// Spawn new effect whenever it has been destroyed by something 
		if(ActiveEffect == nullptr || ActiveEffect.IsBeingDestroyed())
		{
			if(CurrentConsoleValue == 1)
			{
				SpawnSnow();
			}
			else if(CurrentConsoleValue > 1)
			{
				SpawnRain();
			}
		}

		// Have the niagara comp follow the camera
		UpdateActiveEffect();
	}

	void SpawnSnow()
	{
		SpawnEffect(Cast<UNiagaraSystem>(LoadObject(nullptr, "/Game/Effects/FX_Env/EditorPreview/VFX_Preview_Snow.VFX_Preview_Snow")));
	}

	void SpawnRain()
	{
		SpawnEffect(Cast<UNiagaraSystem>(LoadObject(nullptr, "/Game/Effects/FX_Env/EditorPreview/VFX_Preview_Rain.VFX_Preview_Rain")));
	}

	void SpawnEffect(UNiagaraSystem Asset)
	{
		// find primary viewport camera pos
		FVector CameraPos = GetAttachmentLocation();

		// spawn the niagara component with the asset if it hasn't done that already
		if(ActiveEffect == nullptr || ActiveEffect.IsBeingDestroyed())
			ActiveEffect = Niagara::SpawnOneShotNiagaraSystemAtLocation( Asset, CameraPos);

		if(ActiveEffect == nullptr)
		{
			Warning("Tried to spawn snow, but it failed. Please Screenshot this and send it to Sydney");
			return;
		}

		if(ActiveEffect.IsBeingDestroyed())
		{
			PrintToScreen("Can't load snow, it is currently being destroyed");
			return;
		}
	}

	void UpdateActiveEffect()
	{
		if(ActiveEffect == nullptr)
			return;

		// make sure its always active
		if(ActiveEffect.IsActive() == false)
			ActiveEffect.Activate(true);

		// find primary viewport camera pos
		const FVector CameraPos = GetAttachmentLocation();

		// update the location of the niagaracomponent every frame, because we can't attach it to the camera yet. 
		ActiveEffect.SetWorldLocation(CameraPos);

		ActiveEffect.SetVisibility(true);
	}

	FVector GetAttachmentLocation() const
	{
		// find primary viewport camera pos
		FVector CameraPos; FRotator CameraRot;
		const bool bFound = UUnrealEditorSubsystem::Get().GetLevelViewportCameraInfo(CameraPos, CameraRot);

		// offset it slightly to prevent potential camera culling
		CameraPos += CameraRot.ForwardVector*50;

		return CameraPos;
	}

	void DestroyNiagara()
	{
		if(ActiveEffect != nullptr)
		{
			ActiveEffect.DestroyComponent(ActiveEffect);
		}
	}

	void DeactivateNiagara()
	{
		if(ActiveEffect.IsActive())
		{
			ActiveEffect.Deactivate();
		}
	}


	// bool bGameWorldAffectApplied = false;
	// void ApplyEffectToPlayers()
	// {
	// 	if(bGameWorldAffectApplied == false)
	// 	{
	// 		FAngelscriptGameThreadScopeWorldContext ScopeWorldContext(GPWorld.GameInstance);
	// 		auto Mio = Game::GetMio();
	// 		PostProcessing::ApplyCameraParticles(Mio, 
	// 		Cast<UNiagaraSystem>(LoadObject(nullptr, "/Game/Effects/FX_Env/EditorPreview/VFX_Preview_Snow.VFX_Preview_Snow")),
	// 		this, EInstigatePriority::Low
	// 		);
	// 		PrintToScreen("" + Mio);
	// 	}
	// }

};

#endif