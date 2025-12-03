class UAnimInstanceCharacterSelect : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Enter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlayBlendSpaceData Blendspace;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Selected;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHidden; 

	ALobbyCharacterSelectTablet CharSelect;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr)
			return;

		CharSelect = Cast<ALobbyCharacterSelectTablet>(HazeOwningActor);
		if (CharSelect == nullptr)
			return;

		Blendspace.BlendSpace = CharSelect.Blendspace;
		Enter.Sequence = CharSelect.Enter;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (CharSelect == nullptr)
			return;

		Selected = Math::FInterpTo(Selected, CharSelect.bCharacterIsSelected ? 1 : 0, DeltaTime, 5);

		bHidden = CharSelect.Tablet.IsHiddenInGame();
	}
}