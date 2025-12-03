enum ESketchbookWordType
{
	Word,
	Line,
	Dots,
	Exclamations,
};

struct FSketchbookWord
{
#if EDITOR
	UPROPERTY(VisibleInstanceOnly)
	FString Word = "NO_WORD_FOUND";
#endif

	UPROPERTY(EditAnywhere)
	ESketchbookWordType WordType = ESketchbookWordType::Word;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "WordType == ESketchbookWordType::Word", EditConditionHides))
	bool bAllCaps = false;

	UPROPERTY(EditAnywhere)
	FVector2D Origin = FVector2D(0, 30);

	UPROPERTY(EditAnywhere)
	FVector2D Bounds = FVector2D(100, 50);

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0"))
	float PreDelay = 0.0;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.01"))
	float DrawRate = 1.0;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = "0.0"))
	float PostDelay = 0.0;

	void UpdateType(FString InWord)
	{
		bool bIsLine = true;
		bool bIsDots = true;
		bool bIsExclamation = true;

		for(int i = 0; i < InWord.Len(); i++)
		{
			auto Char = InWord[i];
			if(Char != '_')
			{
				bIsLine = false;
			}
			
			if(Char != '.')
			{
				bIsDots = false;
			}

			if(Char != '!')
			{
				bIsExclamation = false;
			}
		}

		WordType = ESketchbookWordType::Word;

		if(bIsLine)
		{
			WordType = ESketchbookWordType::Line;
		}
		else if(bIsDots)
		{
			WordType = ESketchbookWordType::Dots;
		}
		else if(bIsExclamation)
		{
			WordType = ESketchbookWordType::Exclamations;
		}

		bAllCaps = false;
		if(WordType == ESketchbookWordType::Word)
		{
			if(InWord.Compare(InWord.ToUpper(), ESearchCase::CaseSensitive) == 0)
				bAllCaps = true;
		}
	}

	private FTransform GetSentenceWorldTransform(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		return OwnerDrawableSentenceComp.GetTextRenderComponent().WorldTransform;
	}

	FVector GetWorldOrigin(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		const FTransform WorldTransform = GetSentenceWorldTransform(OwnerDrawableSentenceComp);
		const FVector Location = FVector(0, -Origin.X, Origin.Y);
		return WorldTransform.TransformPositionNoScale(Location);
	}

	FVector GetDrawStartLocation(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		const FTransform WorldTransform = GetSentenceWorldTransform(OwnerDrawableSentenceComp);
		const FVector Location = FVector(0, -Origin.X, Origin.Y + OwnerDrawableSentenceComp.DrawHeightOffset);
		return WorldTransform.TransformPositionNoScale(Location);
	}

	FVector GetDrawEndLocation(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		const FTransform WorldTransform = GetSentenceWorldTransform(OwnerDrawableSentenceComp);
		const FVector Location = FVector(0, -Origin.X - GetWordWidth(), Origin.Y + OwnerDrawableSentenceComp.DrawHeightOffset);
		return WorldTransform.TransformPositionNoScale(Location);
	}

	FTransform GetWordWorldTransform(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		const FTransform WorldTransform = GetSentenceWorldTransform(OwnerDrawableSentenceComp);
		const FVector Location = GetWorldOrigin(OwnerDrawableSentenceComp);
		return FTransform(WorldTransform.Rotation, Location);
	}

	void GetWorldBounds(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp, FVector&out Location, FVector&out Extents) const
	{
		const FTransform WorldTransform = GetSentenceWorldTransform(OwnerDrawableSentenceComp);

		Location = FVector(0, -Origin.X, Origin.Y);
		Extents = FVector(0, -Bounds.X, Bounds.Y);

		Location += FVector(0, Extents.Y, 0);
		Location = WorldTransform.TransformPositionNoScale(Location);
	}

	float GetDrawDuration(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp, bool bIncludeDelays) const
	{
		const float WordWidth = GetWordWidth();
		const float DrawSpeed = DrawRate * OwnerDrawableSentenceComp.GetDrawSpeed();
		float Duration = WordWidth / DrawSpeed;

		if(bIncludeDelays)
			Duration += PreDelay + PostDelay;

		return Duration;
	}

	float GetEraseDuration(const USketchbookDrawableSentenceComponent OwnerDrawableSentenceComp) const
	{
		return GetWordWidth() / OwnerDrawableSentenceComp.GetEraseSpeed();
	}

	float GetWordWidth() const
	{
		return Bounds.X * 2;
	}
};