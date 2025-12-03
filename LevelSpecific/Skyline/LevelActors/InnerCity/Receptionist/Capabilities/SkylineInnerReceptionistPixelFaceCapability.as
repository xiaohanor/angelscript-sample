
class USkylineInnerReceptionistPixelFaceCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineInnerReceptionistBot Receptionist;

	float LastDotRight = 0.0;
	ESkylineInnerReceptionistBotState LastState;
	ESkylineInnerReceptionistBotExpression LastExpression;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Receptionist = Cast<ASkylineInnerReceptionistBot>(Owner);
		SkylineInnerReceptionistDevToggles::Expression.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasControl())
			return false;
		if (Receptionist.ExpressionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (LastState != Receptionist.State)
			return true;
		if (Receptionist.ExpressionQueue.IsEmpty())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LastState = Receptionist.State;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!Receptionist.ExpressionQueue.IsEmpty())
			return;

		if (!SkylineInnerReceptionistDevToggles::None.IsEnabled())
		{
			DevFace();
			return;
		}

		switch (Receptionist.State)
		{
			case ESkylineInnerReceptionistBotState::Working:
			{
				NormalFace();
				break;
			}
			case ESkylineInnerReceptionistBotState::Greetings:
			{
				HelloFace();
				Receptionist.ExpressionQueue.Event(this, n"BecomeFriendly");
				break;
			}
			case ESkylineInnerReceptionistBotState::Friendly:
			{
				if (!Receptionist.bForceCat)
					NormalFace();
				MaybeFunnyFace();
				break;
			}
			case ESkylineInnerReceptionistBotState::Laughing:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::xD);
				const float FrameTime = 0.7;
				Receptionist.ExpressionQueue.Event(this, n"FaceXD1");
				Receptionist.ExpressionQueue.Idle(FrameTime);
				Receptionist.ExpressionQueue.Event(this, n"FaceXD2");
				Receptionist.ExpressionQueue.Idle(FrameTime);
				break;
			}
			case ESkylineInnerReceptionistBotState::Schocked:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Shocked);
				Receptionist.ExpressionQueue.Event(this, n"FaceSchocked1");
				Receptionist.ExpressionQueue.Idle(0.2);
				Receptionist.ExpressionQueue.Event(this, n"FaceSchocked2");
				Receptionist.ExpressionQueue.Idle(0.2);
				Receptionist.ExpressionQueue.Event(this, n"BecomeAfraid");
				break;
			}
			case ESkylineInnerReceptionistBotState::Bracing:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Bracing);
				Receptionist.ExpressionQueue.Event(this, n"FaceBracing");
				Receptionist.ExpressionQueue.Idle(1.0);
				Receptionist.ExpressionQueue.Event(this, n"BecomeAnnoyed");
				break;
			}
			case ESkylineInnerReceptionistBotState::Afraid:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Afraid);
				Receptionist.ExpressionQueue.Event(this, n"FaceAfraid");
				Receptionist.ExpressionQueue.Idle(0.33);
				Receptionist.ExpressionQueue.Event(this, n"FaceAfraid2");
				Receptionist.ExpressionQueue.Idle(0.33);
				break;
			}
			case ESkylineInnerReceptionistBotState::WhatAREYouDOING:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Interrobang);
				Receptionist.ExpressionQueue.Event(this, n"FaceQuestion");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"FaceInterrobang");
				Receptionist.ExpressionQueue.Idle(1.0);
				Receptionist.ExpressionQueue.Event(this, n"BecomeAnnoyed");
				break;
			}
			case ESkylineInnerReceptionistBotState::Annoyed:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Annoyed);
				Receptionist.ExpressionQueue.Event(this, n"Pouty");
				Receptionist.ExpressionQueue.Idle(5.0);
				break;
			}
			case ESkylineInnerReceptionistBotState::Hit1:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Hit);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit1");
				Receptionist.ExpressionQueue.Idle(1.0);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit1_2");
				Receptionist.ExpressionQueue.Idle(0.3);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit1_3");
				Receptionist.ExpressionQueue.Idle(10.0);
				break;
			}
			case ESkylineInnerReceptionistBotState::Hit2:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Hit);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit2");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit2_2");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit2");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"FaceHit2_2");
				Receptionist.ExpressionQueue.Idle(10.0);
				break;
			}
			case ESkylineInnerReceptionistBotState::Dead:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Dark);
				Receptionist.ExpressionQueue.Event(this, n"Dark");
				Receptionist.ExpressionQueue.Idle(2.0);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Reboot);
				Receptionist.ExpressionQueue.Event(this, n"BecomeReboot");
				break;
			}
			case ESkylineInnerReceptionistBotState::Rebooting:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Dark);
				Receptionist.ExpressionQueue.Event(this, n"Dark");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Reboot);
				Receptionist.ExpressionQueue.Event(this, n"RebootLoad1");
				Receptionist.ExpressionQueue.Idle(0.3);
				Receptionist.ExpressionQueue.Event(this, n"RebootLoad2");
				Receptionist.ExpressionQueue.Idle(0.5);
				Receptionist.ExpressionQueue.Event(this, n"RebootLoad3");
				Receptionist.ExpressionQueue.Idle(0.3);
				Receptionist.ExpressionQueue.Event(this, n"RebootLoad4");
				Receptionist.ExpressionQueue.Idle(0.35);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Dark);
				Receptionist.ExpressionQueue.Event(this, n"Dark");
				Receptionist.ExpressionQueue.Idle(0.2);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Exterminate);
				Receptionist.ExpressionQueue.Event(this, n"BecomeExterminate");
				break;
			}
			case ESkylineInnerReceptionistBotState::ExterminateMode:
			{
				AnimationExterminate();
				break;
			}
			case ESkylineInnerReceptionistBotState::Smug:
			{
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Smile);
				Receptionist.ExpressionQueue.Event(this, n"HelloHappy");
				Receptionist.ExpressionQueue.Idle(1.0);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Sunglasses);
				Receptionist.ExpressionQueue.Event(this, n"SunglassesP1");
				Receptionist.ExpressionQueue.Idle(0.33);
				Receptionist.ExpressionQueue.Event(this, n"SunglassesP2");
				Receptionist.ExpressionQueue.Idle(0.33);
				Receptionist.ExpressionQueue.Event(this, n"SunglassesP1");
				Receptionist.ExpressionQueue.Idle(0.33);
				Receptionist.ExpressionQueue.Event(this, n"SunglassesP2");
				Receptionist.ExpressionQueue.Idle(0.33);
				Receptionist.ExpressionQueue.Event(this, n"Sunglasses");
				Receptionist.ExpressionQueue.Idle(Math::RandRange(2.0, 4.0));
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Smile);
				Receptionist.ExpressionQueue.Event(this, n"HelloHappy");
				Receptionist.ExpressionQueue.Idle(2.0);
				Receptionist.ExpressionQueue.Event(this, n"BecomeFriendly");
				break;
			}
		}
	}

	UFUNCTION()
	void SetExpression(ESkylineInnerReceptionistBotExpression NewExpression)
	{
		LastExpression = NewExpression;
	}

	void CalculateLookDirection()
	{
		FVector DesiredLookDirection = Receptionist.GetDesiredLookDirection();
		LastDotRight = Receptionist.HeadMesh.WorldRotation.RightVector.DotProduct(DesiredLookDirection);
	}

	UFUNCTION()
	private void BecomeAnnoyed()
	{
		Receptionist.SetState(ESkylineInnerReceptionistBotState::Annoyed);
	}

	UFUNCTION()
	private void BecomeAfraid()
	{
		if (!Receptionist.Busy())
			Receptionist.SetState(ESkylineInnerReceptionistBotState::Afraid);
	}

	UFUNCTION()
	private void BecomeExterminate()
	{
		Receptionist.SetState(ESkylineInnerReceptionistBotState::ExterminateMode);
	}

	UFUNCTION()
	private void BecomeReboot()
	{
		Receptionist.SetState(ESkylineInnerReceptionistBotState::Rebooting);
	}

	UFUNCTION()
	private void BecomeFriendly()
	{
		Receptionist.SetState(ESkylineInnerReceptionistBotState::Friendly);
	}

	UFUNCTION()
	private void Dark()
	{
		Receptionist.CrumbSetDark();
	}	

	private void Worried()
	{
		Receptionist.ExpressionQueue.Event(this, n"FaceWorriedBlink1");
		Receptionist.ExpressionQueue.Idle(0.33);
		Receptionist.ExpressionQueue.Event(this, n"FaceWorriedBlink2");
		Receptionist.ExpressionQueue.Idle(0.33);
		Receptionist.ExpressionQueue.Event(this, n"FaceWorried");
		Receptionist.ExpressionQueue.Idle(Math::RandRange(4.0, 10.0));
	}

	private void NormalFace()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Normal);
		Receptionist.ExpressionQueue.Event(this, n"Blink1");
		Receptionist.ExpressionQueue.Idle(0.1);
		Receptionist.ExpressionQueue.Event(this, n"Blink2");
		Receptionist.ExpressionQueue.Idle(0.1);
		float RandomDuration = Math::RandRange(2.0, 5.0);
		float FrameTime = 0.2;
		for (float iFrame = 0.0; iFrame < RandomDuration; iFrame += FrameTime)
		{
			Receptionist.ExpressionQueue.Event(this, n"Greetings");
			Receptionist.ExpressionQueue.Idle(FrameTime);
		}
	}

	private void HelloFace()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Hello);
		Receptionist.ExpressionQueue.Event(this, n"HelloNormal");
		Receptionist.ExpressionQueue.Idle(0.2);
		Receptionist.ExpressionQueue.Event(this, n"HelloHappy");
		Receptionist.ExpressionQueue.Idle(1.3);
		Receptionist.ExpressionQueue.Event(this, n"Smile");
		Receptionist.ExpressionQueue.Idle(1.3);
	}

	private void MaybeFunnyFace()
	{
		if (Receptionist.LookAtPlayer != nullptr && !Receptionist.bForceCat)
		{
			if (Receptionist.PlayerKarma[Receptionist.LookAtPlayer] > 0)
				AnimationCatFace();
			if (Receptionist.PlayerKarma[Receptionist.LookAtPlayer] < 0)
			{
				Receptionist.ExpressionQueue.Event(this, n"Pouty");
				Receptionist.ExpressionQueue.Idle(4.0);
				Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Worried);
				Worried();
			}
			if (Receptionist.PlayerKarma[Receptionist.LookAtPlayer] != 0)
				return;
		}

		float RandExpression = Math::RandRange(0.0, 1.0);
		if (RandExpression < 0.01 || Receptionist.bForceCat)
		{
			AnimationCatFace();
		}
		else if (RandExpression < 0.05)
		{
			AnimationSmirk();
		}
		else if (RandExpression < 0.15)
		{
			AnimationSunglasses();
		}
		else if (RandExpression < 0.33)
		{
			AnimationUvU();
		}
		else if (RandExpression < 0.66)
		{
			AnimationSmile();
		}
		else if (RandExpression < 0.85)
		{
			HelloFace();
		}
	}

	private void AnimationSunglasses()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Sunglasses);
		Receptionist.ExpressionQueue.Event(this, n"Sunglasses");
		Receptionist.ExpressionQueue.Idle(Math::RandRange(2.0, 4.0));
	}

	private void AnimationUvU()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::uvu);
		Receptionist.ExpressionQueue.Event(this, n"UvU");
		Receptionist.ExpressionQueue.Idle(Math::RandRange(2.0, 4.0));
	}

	private void AnimationSmile()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Smile);
		Receptionist.ExpressionQueue.Event(this, n"Smile");
		Receptionist.ExpressionQueue.Idle(Math::RandRange(2.0, 4.0));
	}

	private void AnimationCatFace()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Cat);
		Receptionist.ExpressionQueue.Event(this, n"CatFaceBlink");
		Receptionist.ExpressionQueue.Idle(0.1);
		Receptionist.ExpressionQueue.Event(this, n"CatFaceHalfBlink");
		Receptionist.ExpressionQueue.Idle(0.1);
		Receptionist.ExpressionQueue.Event(this, n"CatFace");
		Receptionist.ExpressionQueue.Idle(3.0);
		Receptionist.ExpressionQueue.Event(this, n"CatFaceBlink");
		Receptionist.ExpressionQueue.Idle(0.1);
		Receptionist.ExpressionQueue.Event(this, n"CatFaceHalfBlink");
		Receptionist.ExpressionQueue.Idle(0.1);
		Receptionist.ExpressionQueue.Event(this, n"CatFace");
		Receptionist.ExpressionQueue.Idle(3.0);
	}

	private void AnimationSmirk()
	{
		Receptionist.ExpressionQueue.Event(this, n"SetExpression", ESkylineInnerReceptionistBotExpression::Smirk);
		Receptionist.ExpressionQueue.Event(this, n"FaceSmirk1");
		Receptionist.ExpressionQueue.Idle(0.5);
		Receptionist.ExpressionQueue.Event(this, n"FaceSmirk2");
		Receptionist.ExpressionQueue.Idle(0.5);
		Receptionist.ExpressionQueue.Event(this, n"FaceSmirk1");
		Receptionist.ExpressionQueue.Idle(0.5);
		Receptionist.ExpressionQueue.Event(this, n"FaceSmirk2");
		Receptionist.ExpressionQueue.Idle(1.0);
	}

	private void AnimationExterminate()
	{
		Receptionist.ExpressionQueue.Event(this, n"FaceExterminate1");
		Receptionist.ExpressionQueue.Idle(0.5);
		Receptionist.ExpressionQueue.Event(this, n"FaceExterminate2");
		Receptionist.ExpressionQueue.Idle(0.5);
	}

	UFUNCTION()
	private void HelloNormal()
	{
		SkylineInnerReceptionistFaces::EyesNormal(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthHello(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void HelloHappy()
	{
		SkylineInnerReceptionistFaces::EyesHappy(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthHello(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Greetings()
	{
		CalculateLookDirection();
		if (Math::Abs(LastDotRight) < 0.1)
			SkylineInnerReceptionistFaces::EyesNormal(Receptionist.CachedLitLamps);
		else if (LastDotRight > 0.0)
			SkylineInnerReceptionistFaces::EyesNormalRight(Receptionist.CachedLitLamps);
		else
			SkylineInnerReceptionistFaces::EyesNormalLeft(Receptionist.CachedLitLamps);

		SkylineInnerReceptionistFaces::MouthSmile(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Smile()
	{
		SkylineInnerReceptionistFaces::EyesHappy(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmallSmile(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void SunglassesP1()
	{
		SkylineInnerReceptionistFaces::EyesSunglasses(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthP1(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void SunglassesP2()
	{
		SkylineInnerReceptionistFaces::EyesSunglasses(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthP2(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Sunglasses()
	{
		SkylineInnerReceptionistFaces::EyesSunglasses(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmirk(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void UvU()
	{
		SkylineInnerReceptionistFaces::EyesUU(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthV(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Pouty()
	{
		CalculateLookDirection();

		if (Math::Abs(LastDotRight) < 0.1)
		{
			if (Receptionist.PlayersAreOnTop())
				SkylineInnerReceptionistFaces::EyesPoutyUp(Receptionist.CachedLitLamps);
			else
				SkylineInnerReceptionistFaces::EyesPouty(Receptionist.CachedLitLamps);
		}
		else if (LastDotRight > 0.0)
		{
			if (Receptionist.PlayersAreOnTop())
				SkylineInnerReceptionistFaces::EyesPoutyUpRight(Receptionist.CachedLitLamps);
			else
				SkylineInnerReceptionistFaces::EyesPoutyRight(Receptionist.CachedLitLamps);
		}
		else
		{
			if (Receptionist.PlayersAreOnTop())
				SkylineInnerReceptionistFaces::EyesPoutyUpLeft(Receptionist.CachedLitLamps);
			else
				SkylineInnerReceptionistFaces::EyesPoutyLeft(Receptionist.CachedLitLamps);
		}

		SkylineInnerReceptionistFaces::MouthPouty(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Blink1()
	{
		SkylineInnerReceptionistFaces::EyesBlink1(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmile(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void Blink2()
	{
		SkylineInnerReceptionistFaces::EyesBlink2(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmile(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void CatFace()
	{
		SkylineInnerReceptionistFaces::CatFace1(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void CatFaceHalfBlink()
	{
		SkylineInnerReceptionistFaces::CatFace2(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void CatFaceBlink()
	{
		SkylineInnerReceptionistFaces::CatFace3(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	

	UFUNCTION()
	private void FaceQuestion()
	{
		SkylineInnerReceptionistFaces::FaceQuestionmark(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	

	UFUNCTION()
	private void FaceInterrobang()
	{
		SkylineInnerReceptionistFaces::FaceInterrobang(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceSmirk1()
	{
		SkylineInnerReceptionistFaces::EyesBrows1(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmirk(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	
	
	UFUNCTION()
	private void FaceSmirk2()
	{
		SkylineInnerReceptionistFaces::EyesBrows2(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthSmirk(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceHit1()
	{
		SkylineInnerReceptionistFaces::EyesCrocs(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthOhNo(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	
	
	UFUNCTION()
	private void FaceHit1_2()
	{
		SkylineInnerReceptionistFaces::EyesCrocPeek(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthOhNo(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	

	UFUNCTION()
	private void FaceHit1_3()
	{
		SkylineInnerReceptionistFaces::EyesCrocPeek2(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthO(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}	

	UFUNCTION()
	private void FaceHit2()
	{
		SkylineInnerReceptionistFaces::EyesOuch(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthTeeth(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceHit2_2()
	{
		SkylineInnerReceptionistFaces::EyesX(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthTeeth(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void RebootLoad1()
	{
		SkylineInnerReceptionistFaces::FaceLoading1(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void RebootLoad2()
	{
		SkylineInnerReceptionistFaces::FaceLoading2(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void RebootLoad3()
	{
		SkylineInnerReceptionistFaces::FaceLoading3(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void RebootLoad4()
	{
		SkylineInnerReceptionistFaces::FaceLoading4(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceXD1()
	{
		SkylineInnerReceptionistFaces::FacexD1(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceXD2()
	{
		SkylineInnerReceptionistFaces::FacexD2(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceWorried()
	{
		SkylineInnerReceptionistFaces::EyesWorried(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthBlank(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceWorriedBlink1()
	{
		SkylineInnerReceptionistFaces::EyesBlink1(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthBlank(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceWorriedBlink2()
	{
		SkylineInnerReceptionistFaces::EyesBlink2(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthBlank(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceSchocked1()
	{
		SkylineInnerReceptionistFaces::EyesShocked(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthBlank(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceSchocked2()
	{
		SkylineInnerReceptionistFaces::EyesShocked(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthO(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceAfraid()
	{
		SkylineInnerReceptionistFaces::EyesAfraid(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthOhNo(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceAfraid2()
	{
		SkylineInnerReceptionistFaces::EyesAfraid(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthOhNoHigh(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceBracing()
	{
		SkylineInnerReceptionistFaces::EyesCrocs(Receptionist.CachedLitLamps);
		SkylineInnerReceptionistFaces::MouthBlank(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceExterminate1()
	{
		SkylineInnerReceptionistFaces::FaceExterminate1(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	UFUNCTION()
	private void FaceExterminate2()
	{
		SkylineInnerReceptionistFaces::FaceExterminate2(Receptionist.CachedLitLamps);
		Receptionist.UpdateExpression(LastExpression);
	}

	void DevFace()
	{
		if (SkylineInnerReceptionistDevToggles::Normal.IsEnabled())
			NormalFace();
		if (SkylineInnerReceptionistDevToggles::Worried.IsEnabled())
			Worried();
		if (SkylineInnerReceptionistDevToggles::Hello.IsEnabled())
			HelloFace();
		if (SkylineInnerReceptionistDevToggles::Cat.IsEnabled())
			AnimationCatFace();
		if (SkylineInnerReceptionistDevToggles::Smirk.IsEnabled())
			AnimationSmirk();
		if (SkylineInnerReceptionistDevToggles::Sunglasses.IsEnabled())
			AnimationSunglasses();
		if (SkylineInnerReceptionistDevToggles::Smile.IsEnabled())
			AnimationSmile();
		if (SkylineInnerReceptionistDevToggles::UvU.IsEnabled())
			AnimationUvU();
	}
};