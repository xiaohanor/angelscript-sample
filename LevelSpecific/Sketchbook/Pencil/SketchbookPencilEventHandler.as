struct FSketchbookPaperDrawParams
{
	UPROPERTY()
	float DrawTime = 0.0;

	UPROPERTY()
	ESketchbookWordType DrawType = ESketchbookWordType::Word;
}

enum ESketchbookWordSizeType
{
	Small,
	Normal,
	Big
}

struct FSketchbookPencilDrawWordParams
{
	UPROPERTY()
	float DrawTime = 0.0;

	UPROPERTY()
	ESketchbookWordType DrawType = ESketchbookWordType::Word;

	UPROPERTY()
	ESketchbookWordSizeType WordSize = ESketchbookWordSizeType::Normal;

	UPROPERTY()
	bool bIsLastWord = false;

	FSketchbookPencilDrawWordParams(
		const USketchbookDrawableSentenceComponent InDrawableSentenceComp,
		FSketchbookWord InWord,
		bool bInIsLastWord)
	{
		DrawTime = InWord.GetDrawDuration(InDrawableSentenceComp, false);
		DrawType = InWord.WordType;

		auto SketchbookSentence = Cast<ASketchbookSentence>(InDrawableSentenceComp.Owner);
		if(SketchbookSentence.TextWorldSize < 75)
			WordSize = ESketchbookWordSizeType::Small;
		else if(InDrawableSentenceComp.IsAllCaps())	
			WordSize = ESketchbookWordSizeType::Big;
		
		bIsLastWord = bInIsLastWord;		
	}
};

struct FSketchbookPencilEraseSentenceParams
{
	UPROPERTY()
	float EraseTime = 0.0;

	FSketchbookPencilEraseSentenceParams(const USketchbookDrawableSentenceComponent InDrawableSentenceComp)
	{
		EraseTime = InDrawableSentenceComp.GetSentenceEraseDuration();
	}
};

struct FSketchbookPencilDrawObjectParams
{
	UPROPERTY()
	float DrawTime = 0.0;

	FSketchbookPencilDrawObjectParams(const USketchbookDrawableObjectComponent InDrawableObjectComp)
	{
		DrawTime = InDrawableObjectComp.DrawTime;
	}
};

struct FSketchbookPencilEraseObjectParams
{
	UPROPERTY()
	float EraseTime = 0.0;

	FSketchbookPencilEraseObjectParams(const USketchbookDrawableObjectComponent InDrawableObjectComp)
	{
		EraseTime = InDrawableObjectComp.EraseTime;
	}
};

struct FSketchbookPencilDrawPropGroupParams
{
	UPROPERTY()
	float DrawTime = 0.0;

	FSketchbookPencilDrawPropGroupParams(const USketchbookDrawablePropGroupComponent InDrawablePropGroupComp)
	{
		DrawTime = InDrawablePropGroupComp.DrawTime;
	}
};

struct FSketchbookPencilErasePropGroupParams
{
	UPROPERTY()
	float EraseTime = 0.0;

	FSketchbookPencilErasePropGroupParams(const USketchbookDrawablePropGroupComponent InDrawablePropGroupComp)
	{
		EraseTime = InDrawablePropGroupComp.EraseTime;
	}
};

UCLASS(Abstract)
class USketchbookPencilEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ASketchbookPencil Pencil;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMoveTowardsNextDrawable() {}
	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnReachedNextDrawable() {}

	/**
	 * Paper
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPencilTouchPaper() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPencilLiftOffPaper() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEraserTouchPaper() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEraserLiftOffPaper() {}

	/**
	 * Word
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDrawingWord(FSketchbookPencilDrawWordParams DrawWordParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedDrawingWord() {}

	/**
	 * Sentence
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartErasingSentence(FSketchbookPencilEraseSentenceParams EraseSentenceParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedErasingSentence() {}

	/**
	 * Object
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDrawingObject(FSketchbookPencilDrawObjectParams DrawObjectParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedDrawingObject() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartErasingObject(FSketchbookPencilEraseObjectParams EraseObjectParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedErasingObject() {}

	/**
	 * Prop Group
	 */

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartDrawingPropGroup(FSketchbookPencilDrawPropGroupParams DrawPropGroupParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedDrawingPropGroup() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStartErasingPropGroup(FSketchbookPencilErasePropGroupParams ErasePropGroupParams) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnFinishedErasingPropGroup() {}

	UFUNCTION(BlueprintPure)
	USceneComponent GetTipComponent() const
	{
		return Pencil.MeshTipRoot;
	}

	UFUNCTION(BlueprintPure)
	FVector GetTipLocation() const
	{
		return Pencil.MeshTipRoot.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetTipRotation() const
	{
		return Pencil.MeshTipRoot.WorldRotation;
	}

	UFUNCTION(BlueprintPure)
	USceneComponent GetEraserComponent() const
	{
		return Pencil.EraserRoot;
	}

	UFUNCTION(BlueprintPure)
	FVector GetEraserLocation() const
	{
		return Pencil.EraserRoot.WorldLocation;
	}

	UFUNCTION(BlueprintPure)
	FRotator GetEraserRotation() const
	{
		return Pencil.EraserRoot.WorldRotation;
	}
};