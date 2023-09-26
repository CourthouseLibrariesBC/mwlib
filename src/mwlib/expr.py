#! /usr/bin/env python

# Copyright (c) 2007-2009 PediaPress GmbH
# See README.rst for additional licensing information.
# based on pyparsing example code (SimpleCalc.py)

"""Implementation of mediawiki's #expr template.
http://meta.wikimedia.org/wiki/ParserFunctions#.23expr:
"""

import inspect
import math
import re


class ExprError(Exception):
    pass


def _myround(number_to_round, decimal_places):
    if int(decimal_places) == 0 and round(number_to_round + 1) - round(number_to_round) != 1:
        return number_to_round + abs(number_to_round) / number_to_round * 0.5  # simulate Python 2 rounding
        # via https://stackoverflow.com/questions/21839140/
        # python-3-rounding-behavior-in-python-2
    rounded_number = round(number_to_round, int(decimal_places))
    if int(rounded_number) == rounded_number:
        return int(rounded_number)
    return rounded_number


PATTERN = "\n".join(
    [
        r"(?:\s+)",
        r"|((?:(?:\d+)(?:\.\d+)?",
        r" |(?:\.\d+)))",
        r"|(\+|-|\*|/|>=|<=|<>|!=|[a-zA-Z]+|.)",
    ]
)

rx_pattern = re.compile(PATTERN, re.VERBOSE | re.DOTALL | re.IGNORECASE)


def tokenize(s):
    res = []
    for v1, v2 in rx_pattern.findall(s):
        if not (v1 or v2):
            continue
        v2 = v2.lower()
        if v2 in Expr.constants:
            res.append((v2, ""))
        else:
            res.append((v1, v2))
    return res


class UMinus:
    pass


class UPlus:
    pass


precedence = {"(": -1, ")": -1}
functions = {}
unary_ops = set()


def addop(op, prec, fun, numargs=None):
    precedence[op] = prec
    if numargs is None:
        numargs = len(inspect.getfullargspec(fun)[0])

    if numargs == 1:
        unary_ops.add(op)

    def wrap(stack):
        assert len(stack) >= numargs
        args = tuple(stack[-numargs:])
        del stack[-numargs:]
        stack.append(fun(*args))

    functions[op] = wrap


a = addop
a(UMinus, 10, lambda x: -x)
a(UPlus, 10, lambda x: x)
a("^", 10, math.pow, 2)
a("not", 9, lambda x: int(not (bool(x))))
a("abs", 9, abs, 1)
a("sin", 9, math.sin, 1)
a("cos", 9, math.cos, 1)
a("asin", 9, math.asin, 1)
a("acos", 9, math.acos, 1)
a("tan", 9, math.tan, 1)
a("atan", 9, math.atan, 1)
a("exp", 9, math.exp, 1)
a("ln", 9, math.log, 1)
a("ceil", 9, lambda x: int(math.ceil(x)))
a("floor", 9, lambda x: int(math.floor(x)))
a("trunc", 9, int, 1)

a("e", 11, lambda x, y: x * 10**y)
a("E", 11, lambda x, y: x * 10**y)

a("*", 8, lambda x, y: x * y)
a("/", 8, lambda x, y: x / y)
a("div", 8, lambda x, y: x / y)
a("mod", 8, lambda x, y: int(x) % int(y))


a("+", 6, lambda x, y: x + y)
a("-", 6, lambda x, y: x - y)

a("round", 5, _myround)

a("<", 4, lambda x, y: int(x < y))
a(">", 4, lambda x, y: int(x > y))
a("<=", 4, lambda x, y: int(x <= y))
a(">=", 4, lambda x, y: int(x >= y))
a("!=", 4, lambda x, y: int(x != y))
a("<>", 4, lambda x, y: int(x != y))
a("=", 4, lambda x, y: int(x == y))

a("and", 3, lambda x, y: int(bool(x) and bool(y)))
a("or", 2, lambda x, y: int(bool(x) or bool(y)))
del a


class Expr:
    constants = {"e": math.e, "pi": math.pi}

    def as_float_or_int(self, number):
        try:
            return self.constants[number]
        except KeyError:
            pass

        if "." in number:
            return float(number)
        return int(number)

    def output_operator(self, operator):
        return functions[operator](self.operand_stack)

    def output_operand(self, operand):
        self.operand_stack.append(operand)

    def parse_expr(self, expr):
        tokens = tokenize(expr)
        if not tokens:
            return ""

        self.operand_stack = []
        operator_stack = []

        last_operand, last_operator = False, True

        for operand, operator in tokens:
            if operand in ("e",
                           "E") and (last_operand or last_operator == ")"):
                operand, operator = operator, operand

            if operand:
                if last_operand:
                    raise ExprError("expected operator")
                self.output_operand(self.as_float_or_int(operand))
            elif operator == "(":
                operator_stack.append("(")
            elif operator == ")":
                while True:
                    if not operator_stack:
                        raise ExprError("unbalanced parenthesis")
                    char = operator_stack.pop()
                    if char == "(":
                        break
                    self.output_operator(char)
            elif operator in precedence:
                if last_operator and last_operator != ")":
                    if operator == "-":
                        operator = UMinus
                    elif operator == "+":
                        operator = UPlus

                is_unary = operator in unary_ops
                prec = precedence[operator]
                while not is_unary and operator_stack and prec <= precedence[operator_stack[-1]]:
                    char = operator_stack.pop()
                    self.output_operator(char)
                operator_stack.append(operator)
            else:
                raise ExprError(f"unknown operator: {operator!r}")

            last_operand, last_operator = operand, operator

        while operator_stack:
            p = operator_stack.pop()
            if p == "(":
                raise ExprError("unbalanced parenthesis")
            self.output_operator(p)

        if len(self.operand_stack) != 1:
            raise ExprError(f"bad stack: {self.operand_stack}")

        return self.operand_stack[-1]


_cache = {}


def expr(char):
    try:
        return _cache[char]
    except KeyError:
        pass

    parsed_expr = Expr().parse_expr(char)
    _cache[char] = parsed_expr
    return parsed_expr


def main():
    import time

    try:
        import readline  # do not remove. makes raw_input use readline

        readline
    except ImportError:
        pass

    while True:
        input_string = input("> ")
        if not input_string:
            continue

        stime = time.time()
        try:
            res = expr(input_string)
        except Exception as err:
            print("ERROR:", err)
            import traceback

            traceback.print_exc()

            continue
        print(res)
        print(time.time() - stime, "s")


if __name__ == "__main__":
    main()
