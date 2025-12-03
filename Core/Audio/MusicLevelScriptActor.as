
UCLASS(Abstract, HideCategories = "Actor Tick Replication Rendering Collision Disable Cooking")
class AMusicLevelScriptActor : AHazeLevelScriptActor
{
	UPROPERTY()
	TSubclassOf<UHazeMusicSoundDef> MainMusicSoundDef;

	UPROPERTY()
	TSubclassOf<UHazeMusicSoundDef> SequencerMusicSoundDef;

	private TArray<FSoundDefReference> SoundDefReferences;
	private AHazeActor MusicActor;

	UFUNCTION(BlueprintPure)
	AHazeActor GetMusicManagerActor()
	{
		if (MusicActor != nullptr)
			return MusicActor;

		MusicActor = UHazeAudioMusicManager::GetActor();
		return MusicActor;
	}

	private void AddSoundDefAsReference(TSubclassOf<UHazeMusicSoundDef> MusicSoundDefClass, EHazeAudioMusicGroup ExpectedType)
	{
		if(MusicSoundDefClass == nullptr)
			return;

#if EDITOR
		auto DefaultObject = Cast<UHazeMusicSoundDef>(MusicSoundDefClass.Get().GetDefaultObject());

		devCheck(DefaultObject.DefaultMusicGroup == ExpectedType, 
			f"'{DefaultObject.Name}' is expected to be a {ExpectedType} but is {DefaultObject.DefaultMusicGroup}.\n This might be unintended!");
#endif

		FSoundDefReference Ref;
		Ref.SoundDef = MusicSoundDefClass;
		SoundDefReferences.Add(Ref);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddSoundDefAsReference(MainMusicSoundDef, EHazeAudioMusicGroup::Gameplay);
		AddSoundDefAsReference(SequencerMusicSoundDef, EHazeAudioMusicGroup::Sequencer);
		AddSoundDefs(GetMusicManagerActor());

		#if EDITOR
		devCheck(Name.ToString().Contains("Music"), 
			f"This level '{Name}' is a AMusicLevelScript actor, but not named Music! Is this really correct? \n if not, set the correct levelscriptactor class! \n Note: if it's not changed this will distrupt the music system.");
		#endif
	}

	void AddSoundDefs(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return;

		auto ContextComp = USoundDefContextComponent::GetOrCreate(Actor);

		if (ContextComp == nullptr)
			return;

		for (auto& SoundDefRef: SoundDefReferences)
		{
			ContextComp.AddSoundDefInstigator(SoundDefRef, this);
		}
	}

	void RemoveSoundDefs(AHazeActor Actor)
	{
		if (Actor == nullptr)
			return;

		auto ContextComp = USoundDefContextComponent::GetOrCreate(Actor);

		if (ContextComp == nullptr)
			return;

		for (auto& SoundDefRef: SoundDefReferences)
		{
			ContextComp.RemoveSoundDefInstigator(SoundDefRef, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		RemoveSoundDefs(GetMusicManagerActor());
	}

	UFUNCTION()
	void SubscribeToPlayerDeath(AHazePlayerCharacter Player)
	{
		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if (HealthComp == nullptr)
			return;

		HealthComp.OnDeathTriggered.AddUFunction(this, n"OnPlayerDeath");
	}

	UFUNCTION()
	void UnsubscribeToPlayerDeath(AHazePlayerCharacter Player)
	{
		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if (HealthComp == nullptr)
			return;

		HealthComp.OnDeathTriggered.UnbindObject(this);
	}

	UFUNCTION(BlueprintEvent)
	void OnPlayerDeath() {}
}