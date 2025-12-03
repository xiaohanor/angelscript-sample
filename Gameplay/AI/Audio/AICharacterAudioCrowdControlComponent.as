namespace CrowdControl
{
	UAICharacterAudioCrowdControlManager GetManager()
	{
		return UAICharacterAudioCrowdControlManager::GetOrCreate(Game::GetMio());
	}

	UFUNCTION(BlueprintPure)
	mixin int GetFullCrowdSize(UAICharacterAudioCrowdControlComponent Component)
	{
		auto Manager = GetManager();
		if(Manager == nullptr)
			return 0;

		return Manager.GetNumInGroup(Component.GroupTag);
	}
}

struct FCrowdControlGroup
{
	FCrowdControlGroup(const UAICharacterAudioCrowdControlComponent InComponent)
	{
		GroupTag = InComponent.GroupTag;
		Components.Add(InComponent);
	}

	FName GroupTag = NAME_None;
	TArray<UAICharacterAudioCrowdControlComponent> Components;
}

class UCrowdControlTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Crowd Control Temporal Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto Manager = Cast<UAICharacterAudioCrowdControlManager>(Report.AssociatedObject);
		return Manager != nullptr;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{	
		#if TEST
		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle Box = Section.HorizontalBox();	
		if(Box.Button("Toggle Bypass Crowd Control"))
		{
			auto Manager = Cast<UAICharacterAudioCrowdControlManager>(Report.AssociatedObject);
			if(Manager != nullptr)
			{
				Manager.bBypass = !Manager.bBypass;
			}
		}
		#endif		
	}
}

class UAICharacterAudioCrowdControlManager : UActorComponent
{
	private TArray<FCrowdControlGroup> Groups;
	default SetComponentTickEnabled(false);

	#if TEST
	bool bBypass = false;
	#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		#if EDITOR
		TemporalLog::RegisterExtender(this, Game::GetMio(),	 "Crowd Control", n"CrowdControlTemporalLogExtender");
		#endif
	}

	void Register(UAICharacterAudioCrowdControlComponent Component)
	{	
		if(Component.GroupTag == NAME_None)
			return;

		for(auto& Group : Groups)
		{
			if(Group.GroupTag == Component.GroupTag)
			{
				Component.AttenuationRangeSqrd = Group.Components[0].AttenuationRangeSqrd;
				Group.Components.Add(Component);
				return;
			}
		}

		Component.AttenuationRangeSqrd = Math::Square(Component.AttenuationRange);
		Groups.Add(FCrowdControlGroup(Component));
		SetComponentTickEnabled(true);
	}

	void UnRegister(UAICharacterAudioCrowdControlComponent Component)
	{
		if(Component.GroupTag == NAME_None)
			return;

		for(int i = Groups.Num() - 1; i >= 0; --i)
		{
			auto& Group = Groups[i];
			if(Group.GroupTag == Component.GroupTag)
			{
				if(Group.Components.Num() == 1)				
					Groups.RemoveAtSwap(i);				
				else
					Group.Components.RemoveSingleSwap(Component);
				
				return;
			}
		}

		SetComponentTickEnabled(Groups.Num() > 0);
	}

	private void ProcessComponents()
	{
		for(auto& Group : Groups)
		{
			Group.Components.Sort();
			float ItAttenuationValue = 1.0;
			float ItDistSqrd = MAX_flt;
			int NumUsersInMinDistance = 0;
			for(int i = 0; i < Group.Components.Num(); ++i)
			{
				auto Component = Group.Components[i];
				
				#if TEST
				if(bBypass)
				{
					Component.AttenuationValue = 1.0;
					continue;
				}
				#endif

				if(i == 0)
				{
					Component.AttenuationValue = ItAttenuationValue;	
					ItDistSqrd = Component.GetCCDistanceSqrd();				
				}
				else
				{
					if(Component.MinDistance > 0 && NumUsersInMinDistance < Component.MinDistanceInclusionLimit)
					{
						const float DistSqrd = Component.GetCCDistanceSqrd();	
						if(DistSqrd < Math::Square(Component.MinDistance))
						{
							++NumUsersInMinDistance;
							Component.AttenuationValue = 1.0;
							continue;
						}
					}

					const float TargetAttenuationValue = Math::Max(0.0, ItAttenuationValue - Component.StepAttenuation);			
					const float DistanceAlpha = Math::GetMappedRangeValueClamped(FVector2D(ItDistSqrd, ItDistSqrd + Component.AttenuationRangeSqrd), FVector2D(0.0, 1.0), Component.GetCCDistanceSqrd());
					const float LerpedAttenuationValue = Math::Lerp(ItAttenuationValue, TargetAttenuationValue, DistanceAlpha);

					Component.AttenuationValue = LerpedAttenuationValue;
					ItAttenuationValue -= Component.StepAttenuation;	
					ItAttenuationValue = Math::Saturate(ItAttenuationValue);		
				}
			}
		}

		#if Test
		if(!bBypass)
		{
			auto Log = TEMPORAL_LOG(Game::GetMio(), "Crowd Control");
			for(auto& Group : Groups)
			{
				for(int i = 0; i < Group.Components.Num(); ++i)
				{
					auto& Component = Group.Components[i];
					
					const float ColorAlpha = Math::Min(1.0, 0.2 * i);
					FLinearColor CircleColor = FLinearColor(ColorAlpha, 1 - ColorAlpha, 0.0);		
					Log.Circle(f"{Component.GroupTag};{i}", Component.Owner.ActorLocation, 75.f, Rotation = FRotator::MakeFromX(Component.Owner.ActorRotation.ForwardVector), Color = CircleColor);										}
			}
		}
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		ProcessComponents();
	}

	int GetNumInGroup(const FName GroupTag)
	{
		for(const auto& Group : Groups)
		{
			if(Group.GroupTag == GroupTag)
				return Group.Components.Num();
		}

		return 0;
	}
}

class UAICharacterAudioCrowdControlComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FName GroupTag = NAME_None;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Meta = (UIMin = 0.1, UIMax = 0.99, ClampMin = 0.1, ClampMax = 0.9))
	float StepAttenuation = 0.2;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	float AttenuationRange = 1000.0;

	// If set (not 0), any user within this range will not be attenuated (Unless outside of MinDistanceInclusionLimit)
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	float MinDistance = 0.0;

	// Sets the max amount of users allowed to avoid attenuation within MinDistance if set
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Meta = (ClampMin = 1, ClampMax = 100, UIMin = 1, UIMax = 100))
	int MinDistanceInclusionLimit = 10;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	TPerPlayer<bool> TrackPlayers;
	default TrackPlayers[0] = true;
	default TrackPlayers[1] = true;

	access PrivateWithManager = private, UAICharacterAudioCrowdControlManager;
	access:PrivateWithManager
	float AttenuationValue = 1.0;
	access:PrivateWithManager
	float AttenuationRangeSqrd = MAX_flt;

	int opCmp(UAICharacterAudioCrowdControlComponent Other) const
	{
		return GetCCDistanceSqrd() > Other.GetCCDistanceSqrd() ? 1 : -1;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		auto Manager = CrowdControl::GetManager();
		Manager.Register(this);		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		auto Manager = CrowdControl::GetManager();
		Manager.UnRegister(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		auto Manager = CrowdControl::GetManager();
		Manager.Register(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		auto Manager = CrowdControl::GetManager();
		Manager.UnRegister(this);
	}

	float GetCCDistanceSqrd() const
	{
		float DistSqrd = MAX_flt;
		for(auto Player : Game::GetPlayers())
		{
			if(!TrackPlayers[Player])
				continue;

			const float PlayerDistSqrd = Player.ActorLocation.DistSquared(Owner.ActorLocation);
			DistSqrd = Math::Min(DistSqrd, PlayerDistSqrd);
		}

		return DistSqrd;
	} 

	UFUNCTION(BlueprintPure)
	float GetCrowdControlValue()
	{
		return AttenuationValue;
	}
}