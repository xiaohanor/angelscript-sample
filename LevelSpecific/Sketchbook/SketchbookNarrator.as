UCLASS(Abstract)
class ASketchbookNarrator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeVoxCharacterTemplateComponent CharacterTemplateComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	ASketchbookSentence CurrentSentence;

	void PlayNarratorVox(ASketchbookSentence InCurrentSentence)
	{
		if(InCurrentSentence == nullptr)
			return;

		if(InCurrentSentence.VoxAsset == nullptr)
			return;

		CurrentSentence = InCurrentSentence;
		TArray<AHazeActor> Actors;
		Actors.Add(this);

		// "I am Oskar, thou shalt not be granted the OnHazeVoxAssetPlayingStopped delegate!" > ヽ༼ ಠ益ಠ ༽ﾉ
		HazePlayVox(InCurrentSentence.VoxAsset, Actors);

		// "I am Filip, I will just fake it lol" > ヽ༼ຈل͜ຈ༽ﾉ
		Timer::SetTimer(this, n"OnHazeVoxAssetPlayingStopped", Math::Max(InCurrentSentence.VoxAssetDuration, 0.01));
	}

	void CancelNarratorVox()
	{
		if(CurrentSentence == nullptr)
			return;

		HazeVoxStopAsset(CurrentSentence.VoxAsset);
		CurrentSentence = nullptr;
	}

	UFUNCTION()
	private void OnHazeVoxAssetPlayingStopped()
	{
		if(CurrentSentence == nullptr)
			return;

		CurrentSentence.DrawableSentenceComp.RequestNext(CurrentSentence.DrawableSentenceComp.AfterDrawnRequests);
		CurrentSentence = nullptr;
	}

	bool IsPlayingVox() const
	{
		return CurrentSentence != nullptr;
	}
};

namespace Sketchbook
{
	ASketchbookNarrator GetNarrator()
	{
		return TListedActors<ASketchbookNarrator>().Single;
	}
}
