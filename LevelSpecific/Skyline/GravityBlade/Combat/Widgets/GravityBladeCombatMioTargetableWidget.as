UCLASS(Abstract)
class UGravityBladeCombatMioTargetableWidget : UTargetableWidget
{
	UPROPERTY(Meta = (BindWidget))
	UCanvasPanel EnemyCanvas;

	UPROPERTY(Meta = (BindWidget))
	UWidget CrosshairWidget;

	UPROPERTY(BlueprintReadOnly)
	FText DisplayedTargetNameText;

	// Set in UpdateWidget
	FString CurrentTargetDisplayName;

	// Set in OnTargetChanged
	private FString DistortedText;
	private TArray<int> DistortedIndices;
	private TArray<int16> Characters;
	private float LastChangedTime = 0;

	private const float REVEAL_DURATION = 0.2;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		GenerateCharactersArray();
	}

	void OnTakenFromPool() override
	{
		Super::OnTakenFromPool();

		OnTargetChanged();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (TargetHasName())
		{
			if(DistortedIndices.Num() > 0)
			{
				float TimeSinceLastChanged = Time::GameTimeSeconds - LastChangedTime;
				int DesiredRevealedCharacters = Math::FloorToInt(Math::Saturate(TimeSinceLastChanged / REVEAL_DURATION) * DistortedText.Len());
				while(DistortedText.Len() - DistortedIndices.Num() < DesiredRevealedCharacters)
				{
					DistortedIndices.RemoveAtSwap(Math::RandRange(0, DistortedIndices.Num() - 1));
				}
			}

			FString DisplayText = CurrentTargetDisplayName;
			for(int i = 0; i < CurrentTargetDisplayName.Len(); i++)
			{
				if(DistortedIndices.FindIndex(i) >= 0)
					DisplayText[i] = DistortedText[i];
			}
			DisplayedTargetNameText = FText::FromString(DisplayText);
		}

		if(TargetHasName())
		{
			CrosshairWidget.SetVisibility(ESlateVisibility::Collapsed);
			EnemyCanvas.SetVisibility(ESlateVisibility::Visible);
		}
		else
		{
			CrosshairWidget.SetVisibility(ESlateVisibility::Visible);
			EnemyCanvas.SetVisibility(ESlateVisibility::Collapsed);
		}
	}

	bool TargetHasName() const
	{
		if(CurrentTargetDisplayName.IsEmpty())
			return false;

		return true;
	}

	void OnTargetChanged()
	{
		if(!CurrentTargetDisplayName.IsEmpty())
		{
			GenerateRandomString(CurrentTargetDisplayName.Len());
			DisplayedTargetNameText = FText::FromString(DistortedText);
			LastChangedTime = Time::GameTimeSeconds;
		}
		else
		{
			DisplayedTargetNameText = FText::FromString("");
		}
	}

	void GenerateRandomString(int Length)
	{
		DistortedIndices.Reset();

		FString RandomString;

		for(int i = 0; i < Length; i++)
		{
			RandomString.AppendChar(GetRandomCharacter());
			DistortedIndices.Add(i);
		}

		DistortedText = RandomString;
	}

	private int16 GetRandomCharacter() const
	{
		return Characters[Math::RandRange(0, Characters.Num() - 1)];
	}

	private void GenerateCharactersArray()
	{
		Characters.Reset();

		// Upper case
		Characters.Add('A');
		Characters.Add('B');
		Characters.Add('C');
		Characters.Add('D');
		Characters.Add('E');
		Characters.Add('F');
		Characters.Add('G');
		Characters.Add('H');
		Characters.Add('I');
		Characters.Add('J');
		Characters.Add('K');
		Characters.Add('L');
		Characters.Add('M');
		Characters.Add('N');
		Characters.Add('O');
		Characters.Add('P');
		Characters.Add('Q');
		Characters.Add('R');
		Characters.Add('S');
		Characters.Add('T');
		Characters.Add('U');
		Characters.Add('V');
		Characters.Add('W');
		Characters.Add('X');
		Characters.Add('Y');
		Characters.Add('Z');

		// Lower case
		Characters.Add('a');
		Characters.Add('b');
		Characters.Add('c');
		Characters.Add('d');
		Characters.Add('e');
		Characters.Add('f');
		Characters.Add('g');
		Characters.Add('h');
		Characters.Add('i');
		Characters.Add('j');
		Characters.Add('k');
		Characters.Add('l');
		Characters.Add('m');
		Characters.Add('n');
		Characters.Add('o');
		Characters.Add('p');
		Characters.Add('q');
		Characters.Add('r');
		Characters.Add('s');
		Characters.Add('t');
		Characters.Add('u');
		Characters.Add('v');
		Characters.Add('w');
		Characters.Add('x');
		Characters.Add('y');
		Characters.Add('z');

		// Symbols
		Characters.Add('!');
		Characters.Add('@');
		Characters.Add('#');
		Characters.Add('$');
		Characters.Add('%');
		Characters.Add('&');
		Characters.Add('/');
		Characters.Add('(');
		Characters.Add(')');
		Characters.Add('=');
		Characters.Add('+');
		Characters.Add('?');
		Characters.Add('-');
		Characters.Add('*');
		Characters.Add('{');
		Characters.Add('[');
		Characters.Add(']');
		Characters.Add('}');
		Characters.Add('|');
		Characters.Add('<');
		Characters.Add('>');
		Characters.Add('.');
		Characters.Add(' ');
		Characters.Add('~');
		Characters.Add('^');

		// Accents
		Characters.Add('É');
		Characters.Add('é');
		Characters.Add('Å');
		Characters.Add('å');
		Characters.Add('Ä');
		Characters.Add('ä');
		Characters.Add('Ö');
		Characters.Add('ö');
	}
}