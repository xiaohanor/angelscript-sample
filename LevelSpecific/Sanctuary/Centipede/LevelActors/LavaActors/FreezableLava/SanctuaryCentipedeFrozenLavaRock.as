
event void FOnLavaRockMeltedSignature(ASanctuaryCentipedeFrozenLavaRock Rock);

enum ESanctuaryCentipedeFrozenLavaRockState
{
	Freezing,
	Solid,
	Melting,
	Lava,
}

class ASanctuaryCentipedeFrozenLavaRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LavaRockComp;

	UPROPERTY()
	UNiagaraSystem SpawnImpactVFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AliveLoopingVFXComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent DisappearVFXComp;

	UPROPERTY(Category = "Lava")
	FOnLavaRockMeltedSignature OnMeltedEvent;

	UPROPERTY(BlueprintReadOnly)
	ESanctuaryCentipedeFrozenLavaRockState State = ESanctuaryCentipedeFrozenLavaRockState::Lava;

	UPROPERTY()
	float FadeInLavaRockDuration = 2.0;
	float FadeInLavaRockTimer = 0.0;
	FName MaterialFadeMaskName = n"SphereMaskRadius";
	FVector OriginalScale = FVector::OneVector;
	float FadeInLavaRockStartScale = 1.0;
	float FadeInLavaRockEndScale = 1.0;

	UPROPERTY()
	float ShineWhenDoneDuration = 1.0;

	UPROPERTY()
	float FadeOutLavaRockDuration = 5.0;

	float ReturnToLavaDuration = 10.0;
	float ReturnToLavaTimer = 0.0;

	UPROPERTY(BlueprintReadOnly)
	float RockInterpolation = 0.0;

	bool bIsCold = false;
	UPROPERTY()
	bool bShineEnabled = false;
	bool bHasDoneTheShine = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalScale = LavaRockComp.GetWorldScale();
		SetActorTickEnabled(false);
	}

	void Freeze(float StartScale, float EndScale, float Lifetime)
	{
		if (!HasControl())
			return;
		CrumbFreeze(StartScale, EndScale, Lifetime);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFreeze(float StartScale, float EndScale, float Lifetime)
	{
		bIsCold = true;
		ReturnToLavaDuration = Lifetime;
		ReturnToLavaTimer = 0.0;
		if (LavaRockComp != nullptr && LavaRockComp.StaticMesh != nullptr)
		{
			LavaRockComp.SetVisibility(true);
			LavaRockComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
			LavaRockComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			LavaRockComp.SetScalarParameterValueOnMaterials(MaterialFadeMaskName, 0.0);
			FadeInLavaRockStartScale = StartScale;
			FadeInLavaRockEndScale = EndScale;
			LavaRockComp.SetWorldScale3D(OriginalScale * FadeInLavaRockStartScale);
			SetActorTickEnabled(true);
			FadeInLavaRockTimer = 0.0;
			ReturnToLavaTimer = 0.0;
			bHasDoneTheShine = false;
			Niagara::SpawnOneShotNiagaraSystemAttached(SpawnImpactVFX, Root);
			AliveLoopingVFXComp.Activate();
		}
	}

	void ReFreeze()
	{
		if (!HasControl())
			return;
		CrumbReFreeze();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbReFreeze()
	{
		if (ReturnToLavaTimer > SMALL_NUMBER)
		{
			if (State == ESanctuaryCentipedeFrozenLavaRockState::Melting || State == ESanctuaryCentipedeFrozenLavaRockState::Lava)
			{
				USanctuaryCentipedeFrozenLavaRockEventHandler::Trigger_OnReFreeze(this);
				USanctuaryCentipedeFrozenLavaRockManagerEventHandler::Trigger_OnReFreeze(Game::GetMio(), FSanctuaryFrozenLavaRockManagerEventParams(this));
			}
			State = ESanctuaryCentipedeFrozenLavaRockState::Freezing;

			float StartFadeOutTime = ReturnToLavaDuration - FadeOutLavaRockDuration;
			if (ReturnToLavaTimer > StartFadeOutTime) // we have begun fading out, make sure to fade in again!
				FadeInLavaRockTimer = FadeInLavaRockDuration * RockInterpolation;
			ReturnToLavaTimer = 0.0;
		}
	}

	bool IsMelting()
	{
		float StartFadeOutTime = ReturnToLavaDuration - FadeOutLavaRockDuration;
		return ReturnToLavaTimer >= StartFadeOutTime;
	}

	void MeltNowPlz()
	{
		if (!HasControl())
			return;
		CrumbMelt();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMelt()
	{
		float StartFadeOutTime = ReturnToLavaDuration - FadeOutLavaRockDuration;
		if (ReturnToLavaTimer < StartFadeOutTime)
		{
			ReturnToLavaTimer = StartFadeOutTime;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SanctuaryCentipedeDevToggles::Draw::WaterThings.IsEnabled())
		{
			Debug::DrawDebugString(ActorLocation, "" + Math::TruncFloatDecimals(RockInterpolation, 2), ColorDebug::Gray, 0.0, 0.6);
		}

		if (FadeInLavaRockTimer < FadeInLavaRockDuration)
		{
			FadeInLavaRockTimer += DeltaSeconds;

			float Interpolation = Math::Clamp(FadeInLavaRockTimer / FadeInLavaRockDuration, 0.0, 1.0);
			RockInterpolation = Interpolation;
			Interpolation = Math::EaseInOut(0.0, 1.0, Interpolation, 2.0);
			LavaRockComp.SetScalarParameterValueOnMaterials(MaterialFadeMaskName, Interpolation);
			LavaRockComp.SetWorldScale3D(Math::Lerp(OriginalScale * FadeInLavaRockStartScale, OriginalScale * FadeInLavaRockEndScale, Interpolation));

			if (State != ESanctuaryCentipedeFrozenLavaRockState::Freezing)
			{
				USanctuaryCentipedeFrozenLavaRockEventHandler::Trigger_OnStartFreeze(this);
				USanctuaryCentipedeFrozenLavaRockManagerEventHandler::Trigger_OnStartFreeze(Game::GetMio(), FSanctuaryFrozenLavaRockManagerEventParams(this));
			}
			State = ESanctuaryCentipedeFrozenLavaRockState::Freezing;
		}
		else 
		{
			if (ReturnToLavaTimer < ShineWhenDoneDuration && !bHasDoneTheShine && bShineEnabled)
			{
				float Interpolation = Math::Clamp(ReturnToLavaTimer / ShineWhenDoneDuration, 0.0, 1.0);
				Interpolation = Math::EaseOut(-1.0, 2.0, Interpolation, 2.0);
				LavaRockComp.SetScalarParameterValueOnMaterials(n"ShimmerPosition", Interpolation);
			}
			else
			{
				bHasDoneTheShine = true;
			}

			ReturnToLavaTimer += DeltaSeconds;
			float StartFadeOutTime = ReturnToLavaDuration - FadeOutLavaRockDuration;
			if (ReturnToLavaTimer > StartFadeOutTime)
			{
				if (State != ESanctuaryCentipedeFrozenLavaRockState::Melting)
				{
					USanctuaryCentipedeFrozenLavaRockEventHandler::Trigger_OnStartMelt(this);
					USanctuaryCentipedeFrozenLavaRockManagerEventHandler::Trigger_OnStartMelt(Game::GetMio(), FSanctuaryFrozenLavaRockManagerEventParams(this));
				}
				State = ESanctuaryCentipedeFrozenLavaRockState::Melting;

				AliveLoopingVFXComp.Deactivate();
				DisappearVFXComp.Activate();
				float PartialTimer = ReturnToLavaTimer - StartFadeOutTime;
				float Interpolation = Math::Clamp(PartialTimer / FadeOutLavaRockDuration, 0.0, 1.0);
				RockInterpolation = 1.0 - Interpolation;
				LavaRockComp.SetScalarParameterValueOnMaterials(MaterialFadeMaskName, RockInterpolation);
			}
			else
			{
				if (State != ESanctuaryCentipedeFrozenLavaRockState::Solid)
				{
					USanctuaryCentipedeFrozenLavaRockEventHandler::Trigger_OnSolid(this);
					USanctuaryCentipedeFrozenLavaRockManagerEventHandler::Trigger_OnSolid(Game::GetMio(), FSanctuaryFrozenLavaRockManagerEventParams(this));

				}
				State = ESanctuaryCentipedeFrozenLavaRockState::Solid;
			}

			if (ReturnToLavaTimer > ReturnToLavaDuration)
			{
				if (State != ESanctuaryCentipedeFrozenLavaRockState::Lava)
				{
					USanctuaryCentipedeFrozenLavaRockEventHandler::Trigger_OnFullyMelted(this);
					USanctuaryCentipedeFrozenLavaRockManagerEventHandler::Trigger_OnFullyMelted(Game::GetMio(), FSanctuaryFrozenLavaRockManagerEventParams(this));

				}
				State = ESanctuaryCentipedeFrozenLavaRockState::Lava;

				DisappearVFXComp.Deactivate();
				LavaRockComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				LavaRockComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
				LavaRockComp.SetVisibility(false);
				SetActorTickEnabled(false);
				bIsCold = false;
				OnMeltedEvent.Broadcast(this);
			}
		}
	}
};
